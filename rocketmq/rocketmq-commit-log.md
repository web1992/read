# CommitLog

## asyncPutMessage

## mappedFileQueue

## topicQueueTable

## submitFlushRequest

`asyncPutMessage` 方法只是把消息存入到内存 `Buf` 中，并没有真正的存在到磁盘文件中。因此需要执行 `submitFlushRequest` 方法，把内存中的数据存在到磁盘文件中。

通常把内存中的数据同步到磁盘文件过程叫做`刷盘`

```java
// submitFlushRequest 中主要有二个分支，一个是同步的逻辑，一个是异步的逻辑
// 同步的逻辑调用 GroupCommitService 进行持久化
// 异步的逻辑是：唤醒异步线程，直接返回 PUT_OK (因此存在消息丢失的可能)
public CompletableFuture<PutMessageStatus> submitFlushRequest(AppendMessageResult result, MessageExt messageExt) {
    // Synchronization flush
    if (FlushDiskType.SYNC_FLUSH == this.defaultMessageStore.getMessageStoreConfig().getFlushDiskType()) {
        final GroupCommitService service = (GroupCommitService) this.flushCommitLogService;
        if (messageExt.isWaitStoreMsgOK()) {
            GroupCommitRequest request = new GroupCommitRequest(result.getWroteOffset() + result.getWroteBytes(),
                    this.defaultMessageStore.getMessageStoreConfig().getSyncFlushTimeout());
            service.putRequest(request);
            return request.future();
        } else {
            service.wakeup();
            return CompletableFuture.completedFuture(PutMessageStatus.PUT_OK);
        }
    }
    // Asynchronous flush
    else {
        if (!this.defaultMessageStore.getMessageStoreConfig().isTransientStorePoolEnable()) {
            flushCommitLogService.wakeup();
        } else  {
            commitLogService.wakeup();
        }
        return CompletableFuture.completedFuture(PutMessageStatus.PUT_OK);
    }
}
```

## FlushRealTimeService

异步`刷盘`的主要实现类

```java
// run 方法中是主要的 异步刷盘 的实现逻辑
// 首先获取一些配置信息：
// 1. flushCommitLogTimed 是否是实时刷盘
// 2. interval 刷数据到磁盘的间隔，默认500毫秒
// 3. flushPhysicQueueLeastPages 帅盘的时候，每次Page数，默认是4
//    
// 4. flushPhysicQueueThoroughInterval 
public void run() {
    CommitLog.log.info(this.getServiceName() + " service started");
    while (!this.isStopped()) {
        boolean flushCommitLogTimed = CommitLog.this.defaultMessageStore.getMessageStoreConfig().isFlushCommitLogTimed();
        int interval = CommitLog.this.defaultMessageStore.getMessageStoreConfig().getFlushIntervalCommitLog();
        int flushPhysicQueueLeastPages = CommitLog.this.defaultMessageStore.getMessageStoreConfig().getFlushCommitLogLeastPages();
        int flushPhysicQueueThoroughInterval =
            CommitLog.this.defaultMessageStore.getMessageStoreConfig().getFlushCommitLogThoroughInterval();
        boolean printFlushProgress = false;
        // Print flush progress
        long currentTimeMillis = System.currentTimeMillis();
        if (currentTimeMillis >= (this.lastFlushTimestamp + flushPhysicQueueThoroughInterval)) {
            this.lastFlushTimestamp = currentTimeMillis;
            flushPhysicQueueLeastPages = 0;
            printFlushProgress = (printTimes++ % 10) == 0;
        }
        try {
            if (flushCommitLogTimed) {// 如果是实时刷盘，等待500毫秒
                Thread.sleep(interval);
            } else {
                this.waitForRunning(interval);
            }
            if (printFlushProgress) {
                this.printFlushProgress();
            }
            long begin = System.currentTimeMillis();
            CommitLog.this.mappedFileQueue.flush(flushPhysicQueueLeastPages);
            long storeTimestamp = CommitLog.this.mappedFileQueue.getStoreTimestamp();
            if (storeTimestamp > 0) {
                CommitLog.this.defaultMessageStore.getStoreCheckpoint().setPhysicMsgTimestamp(storeTimestamp);
            }
            long past = System.currentTimeMillis() - begin;
            if (past > 500) {
                log.info("Flush data to disk costs {} ms", past);
            }
        } catch (Throwable e) {
            CommitLog.log.warn(this.getServiceName() + " service has exception. ", e);
            this.printFlushProgress();
        }
    }
    // 下面是逻辑只有在退出了while 循环之后，才会执行的逻辑
    // 也就是在线程关闭的时候，执行刷盘，把所有内存中的信息，同步到磁盘
    // Normal shutdown, to ensure that all the flush before exit
    boolean result = false;
    for (int i = 0; i < RETRY_TIMES_OVER && !result; i++) {
        result = CommitLog.this.mappedFileQueue.flush(0);
        CommitLog.log.info(this.getServiceName() + " service shutdown, retry " + (i + 1) + " times " + (result ? "OK" : "Not OK"));
    }
    this.printFlushProgress();
    CommitLog.log.info(this.getServiceName() + " service end");
}
```

## GroupCommitService

同步`刷盘`的主要实现类

`GroupCommitService` 中，有二个字段,`requestsWrite` 和 `requestsRead`,里面存放 `GroupCommitRequest`,使用二个 `List` 存`GroupCommitRequest`
的主要目是避免频繁的读写进行加锁。因此使用二个 `List`,`requestsWrite` 负责临时存放写入请求，而线程会不断的遍历`requestsRead` 负责把数据进行刷盘,
等一轮刷盘之后，清空`requestsRead`,并调用 `swapRequests` 互换二个 `List`.

代码片段如下:

```java
class GroupCommitService extends FlushCommitLogService {
private volatile List<GroupCommitRequest> requestsWrite = new ArrayList<GroupCommitRequest>();
private volatile List<GroupCommitRequest> requestsRead = new ArrayList<GroupCommitRequest>();
}

private void swapRequests() {
    List<GroupCommitRequest> tmp = this.requestsWrite;
    this.requestsWrite = this.requestsRead;
    this.requestsRead = tmp;
}
```

> 思考：这里为什么不使用 `CopyOnWriteArrayList` 呢？原因也很简单，应为 `CopyOnWriteArrayList` 只适合`读`频繁而`写`不频繁的场景， 而 `GroupCommitRequest` 是一次性的。
>
> 即：request 被写入磁盘之后，这数据就不需要了，因此读写都十分的频繁，因此，没有使用。
>
> 而是在 `MappedFileQueue` 中使用了 `CopyOnWriteArrayList` 维护 `MappedFile`,因为 `MappedFile` 映射文件大小都是`1G`(写满一个时间需要很久)，因此不会频繁的创建`MappedFile`和更新`MappedFileQueue`
>
> 使用最多是 `getMappedFile`,因此是：读多写少的创建适合 `CopyOnWriteArrayList` 。
>
> `MappedFile` 是直接映射的`堆外内存`,因此copy并不会占用大量内存，复制的只是`指针`而已。

`GroupCommitService` 核心方法是 `doCommit`

```java
// flushOK 如果刷盘的位置已经超过了请求的位置，则说明刷盘成功
private void doCommit() {
    synchronized (this.requestsRead) {
        if (!this.requestsRead.isEmpty()) {
            for (GroupCommitRequest req : this.requestsRead) {
                // There may be a message in the next file, so a maximum of
                // two times the flush
                boolean flushOK = CommitLog.this.mappedFileQueue.getFlushedWhere() >= req.getNextOffset();
                for (int i = 0; i < 2 && !flushOK; i++) {
                    CommitLog.this.mappedFileQueue.flush(0);
                    flushOK = CommitLog.this.mappedFileQueue.getFlushedWhere() >= req.getNextOffset();
                }
                req.wakeupCustomer(flushOK ? PutMessageStatus.PUT_OK : PutMessageStatus.FLUSH_DISK_TIMEOUT);
            }
            long storeTimestamp = CommitLog.this.mappedFileQueue.getStoreTimestamp();
            if (storeTimestamp > 0) {
                CommitLog.this.defaultMessageStore.getStoreCheckpoint().setPhysicMsgTimestamp(storeTimestamp);
            }
            this.requestsRead.clear();// 清空
        } else {
            // Because of individual messages is set to not sync flush, it
            // will come to this process
            CommitLog.this.mappedFileQueue.flush(0);
        }
    }
}
```

## StoreCheckpoint

```java
long storeTimestamp = CommitLog.this.mappedFileQueue.getStoreTimestamp();

CommitLog.this.defaultMessageStore.getStoreCheckpoint().setPhysicMsgTimestamp(storeTimestamp);
```

## submitReplicaRequest
