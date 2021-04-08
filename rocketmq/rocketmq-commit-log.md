# CommitLog

阅读此文之前，建议先阅读 [RocketMQ 持久化概述](rocketmq-store.md) [MappedFile](rocketmq-mapped-file.md) 这篇文章。

了解 `RocketMQ` 存储的实现概述 和 `MappedFile` 在 `RocketMQ` 中扮演的角色和作用。

- [CommitLog](#commitlog)
  - [CommitLog 的初始化](#commitlog-的初始化)
  - [CommitLog 中的三个线程](#commitlog-中的三个线程)
    - [FlushRealTimeService](#flushrealtimeservice)
    - [GroupCommitService](#groupcommitservice)
    - [CommitRealTimeService](#commitrealtimeservice)
  - [CommitLog putMessage](#commitlog-putmessage)
    - [handleDiskFlush](#handlediskflush)
    - [handleHA](#handleha)
  - [CommitLog asyncPutMessage](#commitlog-asyncputmessage)
    - [asyncPutMessage and submitFlushRequest and submitReplicaRequest](#asyncputmessage-and-submitflushrequest-and-submitreplicarequest)
    - [submitFlushRequest](#submitflushrequest)
    - [submitReplicaRequest](#submitreplicarequest)
  - [DefaultAppendMessageCallback doAppend](#defaultappendmessagecallback-doappend)
  - [MESSAGE_MAGIC_CODE and BLANK_MAGIC_CODE](#message_magic_code-and-blank_magic_code)
  - [CommitLog and ServiceThread](#commitlog-and-servicethread)
  - [CommitLog#topicQueueTable](#commitlogtopicqueuetable)

## CommitLog 的初始化

从 `CommitLog` 的初始化 中可以知道 `CommitLog` 的主要功能是什么，维护日志文件和处理消息。

- 初始化 mappedFileQueue
- 初始化 defaultMessageStore
- 初始化 flushCommitLogService
- 初始化 commitLogService
- 初始化 appendMessageCallback

```java
// CommitLog 的初始
// 这里说下 defaultMessageStore.getMessageStoreConfig().getStorePathCommitLog() 参数
// 默认值是 private String storePathCommitLog = System.getProperty("user.home") + File.separator + "store" + File.separator + "commitlog";
// 在我的电脑的默认路径是：/Users/zl/store/commitlog
public CommitLog(final DefaultMessageStore defaultMessageStore) {
    // 创建 MappedFileQueue
    this.mappedFileQueue = new MappedFileQueue(defaultMessageStore.getMessageStoreConfig().getStorePathCommitLog(),
        defaultMessageStore.getMessageStoreConfig().getMappedFileSizeCommitLog(), defaultMessageStore.getAllocateMappedFileService());
    this.defaultMessageStore = defaultMessageStore;
    // 根据 刷盘的类型，初始化不同的线程
    if (FlushDiskType.SYNC_FLUSH == defaultMessageStore.getMessageStoreConfig().getFlushDiskType()) {
        this.flushCommitLogService = new GroupCommitService();// 同步刷盘线程
    } else {
        this.flushCommitLogService = new FlushRealTimeService();// 异步刷盘线程
    }
    this.commitLogService = new CommitRealTimeService();// 内存同步线程,在开启了 transientStorePoolEnable 才会启动的线程。
    // 初始化 appendMessageCallback 主要作用是把 Msg 转化成 byte[] 方便存储到文件
    this.appendMessageCallback = new DefaultAppendMessageCallback(defaultMessageStore.getMessageStoreConfig().getMaxMessageSize());
    batchEncoderThreadLocal = new ThreadLocal<MessageExtBatchEncoder>() {
        @Override
        protected MessageExtBatchEncoder initialValue() {
            return new MessageExtBatchEncoder(defaultMessageStore.getMessageStoreConfig().getMaxMessageSize());
        }
    };
    // CommitLog 中的锁，保证在写文件的时候，只有一个线程能写入文件
    this.putMessageLock = defaultMessageStore.getMessageStoreConfig().isUseReentrantLockWhenPutMessage() ? new PutMessageReentrantLock() : new PutMessageSpinLock();
}
```

查询 `tree` 命令 路径 `/Users/zl/store`

```sh
pwd
/Users/zl/store
tree .
├── abort
├── checkpoint
├── commitlog
│   └── 00000000000000000000
├── config

# 查看 commitlog 文件夹下面的文件，可以发现有一个大小是 1G 的文件。就是 RocketMQ 的日志文件，也是存储消息的核心文件
ls -lh commitlog
total 11688
-rw-r--r--  1 zl  staff   1.0G  2  6 00:09 00000000000000000000
```

## CommitLog 中的三个线程

- `FlushRealTimeService` 线程，异步刷盘线程。
- `GroupCommitService` 线程，同步刷盘线程。
- `CommitRealTimeService` 线程，内存同步线程。在开启了 `transientStorePoolEnable` 才会启动的线程。

```java
// FlushRealTimeService 和 GroupCommitService 线程，二选一
if (FlushDiskType.SYNC_FLUSH == defaultMessageStore.getMessageStoreConfig().getFlushDiskType()) {
    this.flushCommitLogService = new GroupCommitService();
} else {
    this.flushCommitLogService = new FlushRealTimeService();
}
```

```java
// CommitRealTimeService 线程的开启条件
public boolean isTransientStorePoolEnable() {
    return transientStorePoolEnable && FlushDiskType.ASYNC_FLUSH == getFlushDiskType()
        && BrokerRole.SLAVE != getBrokerRole();
}
```

### FlushRealTimeService

`FlushRealTimeService` 是异步`刷盘`的主要实现类，`GroupCommitService` 是同步`刷盘`的主要实现类。

```java
// FlushRealTimeService#run
// run 方法中是主要的 异步刷盘 的实现逻辑
// 首先获取一些配置信息：
// 1. flushCommitLogTimed 是否是实时刷盘
// 2. interval 刷数据到磁盘的间隔，默认500毫秒
// 3. flushPhysicQueueLeastPages 帅盘的时候，每次Page数，默认是4  
// 4. flushPhysicQueueThoroughInterval 
public void run() {
    CommitLog.log.info(this.getServiceName() + " service started");
    while (!this.isStopped()) {
        // 是否定时刷盘（周期性的），默认是 false
        boolean flushCommitLogTimed = CommitLog.this.defaultMessageStore.getMessageStoreConfig().isFlushCommitLogTimed();
        int interval = CommitLog.this.defaultMessageStore.getMessageStoreConfig().getFlushIntervalCommitLog();
        // 每次刷盘的页数，默认是4页
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
            if (flushCommitLogTimed) {// 如果不是实时刷盘（定时），等待500毫秒
                Thread.sleep(interval);
            } else {
                this.waitForRunning(interval);// 等待唤醒
            }
            if (printFlushProgress) {
                this.printFlushProgress();
            }
            long begin = System.currentTimeMillis();
            // flushPhysicQueueLeastPages=4
            // 意思是每次至少刷新4页数据。但是肯定是存在数据不足四页的情况。
            // 而 flush 方式是有返回值的，当刷盘的数据满足了4页，返回时true
            // 不满足的时候，返回的是false
            // 因此可以知道 FlushRealTimeService 在数据不满足4页的时候，其实不会把数据持久化到磁盘的
            CommitLog.this.mappedFileQueue.flush(flushPhysicQueueLeastPages);// 刷盘
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

// CommitLog.this.mappedFileQueue.flush 底层使用的是 MappedFile#isAbleToFlush 方法
// MappedFile#isAbleToFlush
private boolean isAbleToFlush(final int flushLeastPages) {
    int flush = this.flushedPosition.get();
    int write = getReadPosition();
    if (this.isFull()) {
        return true;
    }
    if (flushLeastPages > 0) {// 如果大于0 根据 write，flush 计算页的大小。
        return ((write / OS_PAGE_SIZE) - (flush / OS_PAGE_SIZE)) >= flushLeastPages;
    }
    return write > flush;
}
```

### GroupCommitService

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

// 把 Msg 放入到 List 中
// GroupCommitRequest 中主要 存在 nextOffset ,执行 flush 以后 超过这个位置，就认为是刷盘成功了。
public synchronized void putRequest(final GroupCommitRequest request) {
    synchronized (this.requestsWrite) {
        this.requestsWrite.add(request);
    }
    this.wakeup();
}
// 互换 List
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
                // 超过 nextOffset ，认为刷盘成功
                // 下面的循环如果第一次失败，会执行两次。原因是因为 mappedFile 有可能满了，
                // 会写入的是 空消息。 然后创建新的 mappedFile, 此时 FlushedWhere 可能不满足，则就进行重试。
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

### CommitRealTimeService

`CommitRealTimeService` 是一个异步 执行 commit 的线程

这里再次说明 CommitLog 中 `commit` 与 `flush` 的区别：

>`commit` 与 `flush` 相比，`commit` 只会执行文件的 `write` 操作，此操作并不会立即把内存中的数据下入到磁盘中。
>而 `flush` 操作则会执行 `force`，强制把内存中的数据刷新到磁盘。

`CommitRealTimeService` 线程的目的是操作 `MappedFile` 中的 `ByteBuffer writeBuffer` 。通过 `commit` 调用把 `writeBuffer` (内存中的数据) 写到 `fileChannel` 缓冲中，等待操作系统真正的写入文件。

```java
// 初始化
this.commitLogService = new CommitRealTimeService();
//...
// 根据配置来确定是否启动
public void start() {
    this.flushCommitLogService.start();
    if (defaultMessageStore.getMessageStoreConfig().isTransientStorePoolEnable()) {
        // 根据配置查询是否需要启动此线程
        this.commitLogService.start();
    }
}
```

```java
// CommitRealTimeService commit 的业务逻辑
public void run() {
    CommitLog.log.info(this.getServiceName() + " service started");
    while (!this.isStopped()) {
        int interval = CommitLog.this.defaultMessageStore.getMessageStoreConfig().getCommitIntervalCommitLog();
        int commitDataLeastPages = CommitLog.this.defaultMessageStore.getMessageStoreConfig().getCommitCommitLogLeastPages();
        int commitDataThoroughInterval =
            CommitLog.this.defaultMessageStore.getMessageStoreConfig().getCommitCommitLogThoroughInterval();
        long begin = System.currentTimeMillis();
        if (begin >= (this.lastCommitTimestamp + commitDataThoroughInterval)) {
            this.lastCommitTimestamp = begin;
            commitDataLeastPages = 0;
        }
        try {
            // 执行commit 操作
            boolean result = CommitLog.this.mappedFileQueue.commit(commitDataLeastPages);
            long end = System.currentTimeMillis();
            if (!result) {
                this.lastCommitTimestamp = end; // result = false means some data committed.
                //now wake up flush thread.
                flushCommitLogService.wakeup();
            }
            if (end - begin > 500) {
                log.info("Commit data to file costs {} ms", end - begin);
            }
            this.waitForRunning(interval);
        } catch (Throwable e) {
            CommitLog.log.error(this.getServiceName() + " service has exception. ", e);
        }
    }// while end
    boolean result = false;
    for (int i = 0; i < RETRY_TIMES_OVER && !result; i++) {// 线程被关闭时，执行清理操作
        result = CommitLog.this.mappedFileQueue.commit(0);
        CommitLog.log.info(this.getServiceName() + " service shutdown, retry " + (i + 1) + " times " + (result ? "OK" : "Not OK"));
    }
    CommitLog.log.info(this.getServiceName() + " service end");
}
```

## CommitLog putMessage

`putMessage` 方法有四种，如下，异步的两组，同步的两组。分别支`持批量消息`和`非批量消息`的存储。

```java
// 异步的
CompletableFuture<PutMessageResult> asyncPutMessage(final MessageExtBrokerInner msg)
CompletableFuture<PutMessageResult> asyncPutMessages(final MessageExtBatch messageExtBatch)
// 同步的
PutMessageResult putMessage(final MessageExtBrokerInner msg)
PutMessageResult putMessages(final MessageExtBatch messageExtBatch)
```

```java
public PutMessageResult putMessage(MessageExtBrokerInner msg) {
    PutMessageStatus checkStoreStatus = this.checkStoreStatus();
    if (checkStoreStatus != PutMessageStatus.PUT_OK) {
        return new PutMessageResult(checkStoreStatus, null);
    }
    PutMessageStatus msgCheckStatus = this.checkMessage(msg);
    if (msgCheckStatus == PutMessageStatus.MESSAGE_ILLEGAL) {
        return new PutMessageResult(msgCheckStatus, null);
    }
    long beginTime = this.getSystemClock().now();
    PutMessageResult result = this.commitLog.putMessage(msg);// 存储消息
    long elapsedTime = this.getSystemClock().now() - beginTime;
    if (elapsedTime > 500) {
        log.warn("not in lock elapsed time(ms)={}, bodyLength={}", elapsedTime, msg.getBody().length);
    }
    this.storeStatsService.setPutMessageEntireTimeMax(elapsedTime);
    if (null == result || !result.isOk()) {
        this.storeStatsService.getPutMessageFailedTimes().incrementAndGet();
    }
    return result;
}
// 1. 事物消息的特殊处理
// 2. 找到 mappedFile 
// 3. putMessageLock 锁
// 4. 执行 mappedFile.appendMessage 逻辑主要回调方法中执行 DefaultAppendMessageCallback
// 5. 释放 putMessageLock 锁
// 6. 判断执行结果 
// 7. 更新统计信息
// 8. handleDiskFlush
// 9. handleHA
// 10. 返回 PutMessageResult
public PutMessageResult putMessage(final MessageExtBrokerInner msg) {
// ...
}
```

### handleDiskFlush

```java
// 此方式执行之前，消息已经 MessageExtBrokerInner 写入到 ByteBuffer 中了
// 此方法的主要作用就是，进行消息的持久化到文件的处理
public void handleDiskFlush(AppendMessageResult result, PutMessageResult putMessageResult, MessageExt messageExt) {
    // Synchronization flush 同步刷盘
    if (FlushDiskType.SYNC_FLUSH == this.defaultMessageStore.getMessageStoreConfig().getFlushDiskType()) {
        final GroupCommitService service = (GroupCommitService) this.flushCommitLogService;
        if (messageExt.isWaitStoreMsgOK()) {// 是否等待消息存储OK，默认是 true
            GroupCommitRequest request = new GroupCommitRequest(result.getWroteOffset() + result.getWroteBytes());
            service.putRequest(request);// 放入 GroupCommitService 线程中，等待处理
            CompletableFuture<PutMessageStatus> flushOkFuture = request.future();
            PutMessageStatus flushStatus = null;
            try {// 执行 flushOkFuture.get 同步的获取执行结果
                flushStatus = flushOkFuture.get(this.defaultMessageStore.getMessageStoreConfig().getSyncFlushTimeout(),
                        TimeUnit.MILLISECONDS);
            } catch (InterruptedException | ExecutionException | TimeoutException e) {
                //flushOK=false;
            }
            if (flushStatus != PutMessageStatus.PUT_OK) {
                log.error("do groupcommit, wait for flush failed, topic: " + messageExt.getTopic() + " tags: " + messageExt.getTags()
                    + " client address: " + messageExt.getBornHostString());
                putMessageResult.setPutMessageStatus(PutMessageStatus.FLUSH_DISK_TIMEOUT);
            }
        } else {
            service.wakeup();// 线程唤醒
        }
    }
    // Asynchronous flush 异步刷盘
    else {
        if (!this.defaultMessageStore.getMessageStoreConfig().isTransientStorePoolEnable()) {
            flushCommitLogService.wakeup();
        } else {
            commitLogService.wakeup();
        }
    }
}
```

### handleHA

`handleHA` 同步 `SLAVE` 的操作。

```java
public void handleHA(AppendMessageResult result, PutMessageResult putMessageResult, MessageExt messageExt) {
    if (BrokerRole.SYNC_MASTER == this.defaultMessageStore.getMessageStoreConfig().getBrokerRole()) {
        HAService service = this.defaultMessageStore.getHaService();
        if (messageExt.isWaitStoreMsgOK()) {
            // Determine whether to wait
            if (service.isSlaveOK(result.getWroteOffset() + result.getWroteBytes())) {
                // 包装成 GroupCommitRequest
                GroupCommitRequest request = new GroupCommitRequest(result.getWroteOffset() + result.getWroteBytes());
                service.putRequest(request);// 提交给 HAService 处理
                service.getWaitNotifyObject().wakeupAll();
                PutMessageStatus replicaStatus = null;
                try {
                    // 等待&获取 处理结果
                    replicaStatus = request.future().get(this.defaultMessageStore.getMessageStoreConfig().getSyncFlushTimeout(),
                            TimeUnit.MILLISECONDS);
                } catch (InterruptedException | ExecutionException | TimeoutException e) {
                }
                if (replicaStatus != PutMessageStatus.PUT_OK) {
                    log.error("do sync transfer other node, wait return, but failed, topic: " + messageExt.getTopic() + " tags: "
                        + messageExt.getTags() + " client address: " + messageExt.getBornHostNameString());
                    putMessageResult.setPutMessageStatus(PutMessageStatus.FLUSH_SLAVE_TIMEOUT);
                }
            }
            // Slave problem
            else {
                // Tell the producer, slave not available
                putMessageResult.setPutMessageStatus(PutMessageStatus.SLAVE_NOT_AVAILABLE);
            }
        }
    }
}
```

## CommitLog asyncPutMessage

`asyncPutMessage` 异步存储消息

```java
// asyncPutMessage
// 1. 事物消息的特殊处理
// 2. 找到 mappedFile 
// 3. putMessageLock 锁
// 4. 执行 mappedFile.appendMessage 逻辑主要回调方法中执行 DefaultAppendMessageCallback
// 5. 释放 putMessageLock 锁
// 6. 判断执行结果 
// 7. 更新统计信息
// 8. 执行 submitFlushRequest
// 9. 执行 submitReplicaRequest
// 10. 返回 CompletableFuture<PutMessageResult>
public CompletableFuture<PutMessageResult> asyncPutMessage(final MessageExtBrokerInner msg) {
// ...
}
```

### asyncPutMessage and submitFlushRequest and submitReplicaRequest

`asyncPutMessage` 方法只是把消息存入到内存 `Buf` 中，并没有真正的存在到磁盘文件中。因此需要执行 `submitFlushRequest` 方法，把内存中的数据存在到磁盘文件中。

通常把内存中的数据同步到磁盘文件过程叫做`刷盘`

### submitFlushRequest

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

### submitReplicaRequest

`submitReplicaRequest` 执行 `SLAVE` 同步操作，`RocketMQ` 高可用的实现流程。

```java
public CompletableFuture<PutMessageStatus> submitReplicaRequest(AppendMessageResult result, MessageExt messageExt) {
    if (BrokerRole.SYNC_MASTER == this.defaultMessageStore.getMessageStoreConfig().getBrokerRole()) {
        HAService service = this.defaultMessageStore.getHaService();
        if (messageExt.isWaitStoreMsgOK()) {
            if (service.isSlaveOK(result.getWroteBytes() + result.getWroteOffset())) {
                GroupCommitRequest request = new GroupCommitRequest(result.getWroteOffset() + result.getWroteBytes(),
                        this.defaultMessageStore.getMessageStoreConfig().getSyncFlushTimeout());
                service.putRequest(request);
                service.getWaitNotifyObject().wakeupAll();
                return request.future();
            }
            else {
                return CompletableFuture.completedFuture(PutMessageStatus.SLAVE_NOT_AVAILABLE);
            }
        }
    }
    return CompletableFuture.completedFuture(PutMessageStatus.PUT_OK);
}
```

## DefaultAppendMessageCallback doAppend

`MessageExtBrokerInner`/`MessageExtBatch` -> 到 `ByteBuffer` 的实现过程（序列化）

```java
// 单个消息  
AppendMessageResult doAppend(final long fileFromOffset, final ByteBuffer byteBuffer,
     final int maxBlank, final MessageExtBrokerInner msg);
// 批量的消息
AppendMessageResult doAppend(final long fileFromOffset, final ByteBuffer byteBuffer,
     final int maxBlank, final MessageExtBatch messageExtBatch);
```

```java
// 1. ByteBuffer 参数是从 MappedFile 获取的，可能是 内存的 ByteBuffer ，也可能是直接内存 MappedByteBuffer
// 2. doAppend 主要是把 MessageExtBrokerInner 进行序列化，存储在 ByteBuffer 中
public AppendMessageResult doAppend(final long fileFromOffset, final ByteBuffer byteBuffer, final int maxBlank,
    final MessageExtBrokerInner msgInner) {
// ...
}
```

代码的完整逻辑可以在 [CommitLog.AppendMessageResult.doAppend](https://github.com/apache/rocketmq/blob/master/store/src/main/java/org/apache/rocketmq/store/CommitLog.java#L1521) 找到

## MESSAGE_MAGIC_CODE and BLANK_MAGIC_CODE

先看它们的定义

```java
// Message's MAGIC CODE daa320a7
public final static int MESSAGE_MAGIC_CODE = -626843481;
// End of file empty MAGIC CODE cbd43194
protected final static int BLANK_MAGIC_CODE = -875286124;
```

`CommitLog` 使用 `BLANK_MAGIC_CODE` 和 `MESSAGE_MAGIC_CODE` 来区分 空消息和正常消息。

空消息的含义：当向 `MappedFile` 写入消息的时候，`MappedFile`文件大小已经快满了，不足以存放当前的消息。那么就会创建空消息进行填充`MappedFile`文件。

使用空消息填充的代码如下：

```java
// Determines whether there is sufficient free space
if ((msgLen + END_FILE_MIN_BLANK_LENGTH) > maxBlank) {// 空间不足
    this.resetByteBuffer(this.msgStoreItemMemory, maxBlank);
    // 1 TOTALSIZE
    this.msgStoreItemMemory.putInt(maxBlank);// 填充剩下的空间
    // 2 MAGICCODE
    this.msgStoreItemMemory.putInt(CommitLog.BLANK_MAGIC_CODE);// 填充 magic_code
    // 3 The remaining space may be any value
    // Here the length of the specially set maxBlank
    final long beginTimeMills = CommitLog.this.defaultMessageStore.now();
    byteBuffer.put(this.msgStoreItemMemory.array(), 0, maxBlank);
    // 返回 END_OF_FILE ，上层调用方会根据 END_OF_FILE 结果。重新写入文件（创建MappedFile,并写入消息），
    return new AppendMessageResult(AppendMessageStatus.END_OF_FILE, wroteOffset, maxBlank, msgId, msgInner.getStoreTimestamp(),
        queueOffset, CommitLog.this.defaultMessageStore.now() - beginTimeMills);
}
```

## CommitLog and ServiceThread

上面提到过 `CommitLog` 中有三个线程 `FlushRealTimeService` ,`GroupCommitService` ,`CommitRealTimeService`  。

而这三个线程都继承来自 `ServiceThread` ,支持 `wakeup`,`waitForRunning` 等操作，下面看其中的设计技巧。

以 `GroupCommitService` 为例子

```java
// submitFlushRequest 中 flushCommitLogService.wakeup() 唤醒
public CompletableFuture<PutMessageStatus> submitFlushRequest(AppendMessageResult result, MessageExt messageExt) {
    // Synchronization flush
    if (FlushDiskType.SYNC_FLUSH == this.defaultMessageStore.getMessageStoreConfig().getFlushDiskType()) {
        // ...
    }
    // Asynchronous flush
    else {
        if (!this.defaultMessageStore.getMessageStoreConfig().isTransientStorePoolEnable()) {
            flushCommitLogService.wakeup();// 被唤醒
        } else  {
            commitLogService.wakeup();
        }
        return CompletableFuture.completedFuture(PutMessageStatus.PUT_OK);
    }
}

// putRequest 操作的唤醒
public synchronized void putRequest(final GroupCommitRequest request) {
    synchronized (this.requestsWrite) {
        this.requestsWrite.add(request);
    }
    this.wakeup();// 被唤醒
}

// GroupCommitService 的 run 方法
public void run() {
    CommitLog.log.info(this.getServiceName() + " service started");
    while (!this.isStopped()) {
        try {
            this.waitForRunning(10);// 等待10毫秒
            this.doCommit();// 执行 commit 操作
        } catch (Exception e) {
            CommitLog.log.warn(this.getServiceName() + " service has exception. ", e);
        }
    }
    // ...
}
```

从上面的代码片段中，可以知道，在提交了 request 请求之后，线程会被唤醒。而在 while 循环中 会执行 waitForRunning 操作。

```java
// ServiceThread 的变量
protected volatile AtomicBoolean hasNotified = new AtomicBoolean(false);
protected final CountDownLatch2 waitPoint = new CountDownLatch2(1);

// ...
public void wakeup() {
    // 把 hasNotified 改成 true 
    // 如果修改成功 执行 countDown，如果有线程在 await 中，则会被立刻唤醒
    if (hasNotified.compareAndSet(false, true)) {
        waitPoint.countDown(); // notify
    }
}
protected void waitForRunning(long interval) {
    // 把 hasNotified 改成 false
    // 修改成功说明 执行过了 wakeup 了，有任务需要处理，则返回去执行业务逻辑
    if (hasNotified.compareAndSet(true, false)) { // boolean expect, boolean update
        this.onWaitEnd();
        return;// 返回，不需要等待
    }
    //entry to wait
    waitPoint.reset();// 重置，意味着下面的 await 一定会进入阻塞状态。最多10毫秒。
    try {
        waitPoint.await(interval, TimeUnit.MILLISECONDS);// 等待10毫秒 或者 被唤醒
    } catch (InterruptedException e) {
        log.error("Interrupted", e);
    } finally {
        hasNotified.set(false);
        this.onWaitEnd();
    }
}
```

从上面的代码逻辑可以知道。`GroupCommitService` 线程会进入阻塞（让出CPU）最多10毫秒,然而，这个10毫秒是必须的。

如果不阻塞10毫秒，线程会一直占用CPU（即使没有要处理的消息也占用CPU，就变成了 while(true) ）。

上面的逻辑与 `阻塞队列` 类似，有任务的时候(被唤醒)就执行业务，没有任务的时候就进入阻塞。

## CommitLog#topicQueueTable

参考 [org.apache.rocketmq.store.ConsumeQueue](rocketmq-consume-queue.md)
