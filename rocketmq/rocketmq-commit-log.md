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
  - [DefaultAppendMessageCallback doAppend](#defaultappendmessagecallback-doappend)
  - [CommitLog#topicQueueTable](#commitlogtopicqueuetable)
  - [submitFlushRequest](#submitflushrequest)
  - [StoreCheckpoint](#storecheckpoint)
  - [submitReplicaRequest](#submitreplicarequest)

## CommitLog 的初始化

从 CommitLog 的初始化 中可以知道 CommitLog 的主要功能是什么，维护日志文件和处理消息。

- 初始化 mappedFileQueue
- 初始化 defaultMessageStore
- 初始化 flushCommitLogService
- 初始化 commitLogService
- 初始化 appendMessageCallback

```java
// CommitLog 的初始
public CommitLog(final DefaultMessageStore defaultMessageStore) {
    this.mappedFileQueue = new MappedFileQueue(defaultMessageStore.getMessageStoreConfig().getStorePathCommitLog(),
        defaultMessageStore.getMessageStoreConfig().getMappedFileSizeCommitLog(), defaultMessageStore.getAllocateMappedFileService());
    this.defaultMessageStore = defaultMessageStore;
    if (FlushDiskType.SYNC_FLUSH == defaultMessageStore.getMessageStoreConfig().getFlushDiskType()) {
        this.flushCommitLogService = new GroupCommitService();
    } else {
        this.flushCommitLogService = new FlushRealTimeService();
    }
    this.commitLogService = new CommitRealTimeService();
    this.appendMessageCallback = new DefaultAppendMessageCallback(defaultMessageStore.getMessageStoreConfig().getMaxMessageSize());
    batchEncoderThreadLocal = new ThreadLocal<MessageExtBatchEncoder>() {
        @Override
        protected MessageExtBatchEncoder initialValue() {
            return new MessageExtBatchEncoder(defaultMessageStore.getMessageStoreConfig().getMaxMessageSize());
        }
    };
    this.putMessageLock = defaultMessageStore.getMessageStoreConfig().isUseReentrantLockWhenPutMessage() ? new PutMessageReentrantLock() : new PutMessageSpinLock();
}
```

## CommitLog 中的三个线程

- FlushRealTimeService 线程，异步线程。
- GroupCommitService 线程，同步线程。
- CommitRealTimeService 线程，在开启了 transientStorePoolEnable 才会启动的线程。

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

### CommitRealTimeService

`CommitRealTimeService` 是一个异步 执行 commit 的线程

`commit` 与 `flush` 相比，`commit` 只会执行文件的 `write` 操作，此操作并不会立即把内存中的数据下入到磁盘中。

而 `flush` 操作则会执行 `force`，强制把内存中的数据刷新到磁盘。

`CommitRealTimeService` 线程的目的是操作 `MappedFile` 中的 `ByteBuffer writeBuffer` 。通过 `commit` 调用把 `writeBuffer` (内存中的数据) 写到 `fileChannel` 中

缓冲中，等待操作系统真正的写入文件。

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
// commit 的业务逻辑
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
    PutMessageResult result = this.commitLog.putMessage(msg);
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
// 3. 执行 mappedFile.appendMessage 逻辑主要回调方法中执行 DefaultAppendMessageCallback
// 4. 判断执行结果 
// 5. 更新统计信息
// 6. handleDiskFlush
// 7. handleHA
public PutMessageResult putMessage(final MessageExtBrokerInner msg) {
// ...
}
```

## DefaultAppendMessageCallback doAppend

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
    // STORETIMESTAMP + STOREHOSTADDRESS + OFFSET <br>
    // PHY OFFSET
    long wroteOffset = fileFromOffset + byteBuffer.position();
    int sysflag = msgInner.getSysFlag();
    int bornHostLength = (sysflag & MessageSysFlag.BORNHOST_V6_FLAG) == 0 ? 4 + 4 : 16 + 4;
    int storeHostLength = (sysflag & MessageSysFlag.STOREHOSTADDRESS_V6_FLAG) == 0 ? 4 + 4 : 16 + 4;
    ByteBuffer bornHostHolder = ByteBuffer.allocate(bornHostLength);
    ByteBuffer storeHostHolder = ByteBuffer.allocate(storeHostLength);
    this.resetByteBuffer(storeHostHolder, storeHostLength);
    String msgId;// = storeHostHolder + wroteOffset = 存储的IP 地址 + wroteOffset
    if ((sysflag & MessageSysFlag.STOREHOSTADDRESS_V6_FLAG) == 0) {
        msgId = MessageDecoder.createMessageId(this.msgIdMemory, msgInner.getStoreHostBytes(storeHostHolder), wroteOffset);
    } else {
        msgId = MessageDecoder.createMessageId(this.msgIdV6Memory, msgInner.getStoreHostBytes(storeHostHolder), wroteOffset);
    }
    // Record ConsumeQueue information
    keyBuilder.setLength(0);
    keyBuilder.append(msgInner.getTopic());
    keyBuilder.append('-');
    keyBuilder.append(msgInner.getQueueId());
    String key = keyBuilder.toString();
    Long queueOffset = CommitLog.this.topicQueueTable.get(key);
    if (null == queueOffset) {
        queueOffset = 0L;
        CommitLog.this.topicQueueTable.put(key, queueOffset);
    }
    // Transaction messages that require special handling
    final int tranType = MessageSysFlag.getTransactionValue(msgInner.getSysFlag());
    switch (tranType) {
        // Prepared and Rollback message is not consumed, will not enter the
        // consumer queuec
        case MessageSysFlag.TRANSACTION_PREPARED_TYPE:
        case MessageSysFlag.TRANSACTION_ROLLBACK_TYPE:
            queueOffset = 0L;
            break;
        case MessageSysFlag.TRANSACTION_NOT_TYPE:
        case MessageSysFlag.TRANSACTION_COMMIT_TYPE:
        default:
            break;
    }
    /**
     * Serialize message
     */
    final byte[] propertiesData =
        msgInner.getPropertiesString() == null ? null : msgInner.getPropertiesString().getBytes(MessageDecoder.CHARSET_UTF8);
    final int propertiesLength = propertiesData == null ? 0 : propertiesData.length;
    if (propertiesLength > Short.MAX_VALUE) {
        log.warn("putMessage message properties length too long. length={}", propertiesData.length);
        return new AppendMessageResult(AppendMessageStatus.PROPERTIES_SIZE_EXCEEDED);
    }
    final byte[] topicData = msgInner.getTopic().getBytes(MessageDecoder.CHARSET_UTF8);
    final int topicLength = topicData.length;
    final int bodyLength = msgInner.getBody() == null ? 0 : msgInner.getBody().length;
    final int msgLen = calMsgLength(msgInner.getSysFlag(), bodyLength, topicLength, propertiesLength);
    // Exceeds the maximum message
    if (msgLen > this.maxMessageSize) {
        CommitLog.log.warn("message size exceeded, msg total size: " + msgLen + ", msg body size: " + bodyLength
            + ", maxMessageSize: " + this.maxMessageSize);
        return new AppendMessageResult(AppendMessageStatus.MESSAGE_SIZE_EXCEEDED);
    }
    // Determines whether there is sufficient free space
    if ((msgLen + END_FILE_MIN_BLANK_LENGTH) > maxBlank) {
        this.resetByteBuffer(this.msgStoreItemMemory, maxBlank);
        // 1 TOTALSIZE
        this.msgStoreItemMemory.putInt(maxBlank);
        // 2 MAGICCODE
        this.msgStoreItemMemory.putInt(CommitLog.BLANK_MAGIC_CODE);
        // 3 The remaining space may be any value
        // Here the length of the specially set maxBlank
        final long beginTimeMills = CommitLog.this.defaultMessageStore.now();
        byteBuffer.put(this.msgStoreItemMemory.array(), 0, maxBlank);
        return new AppendMessageResult(AppendMessageStatus.END_OF_FILE, wroteOffset, maxBlank, msgId, msgInner.getStoreTimestamp(),
            queueOffset, CommitLog.this.defaultMessageStore.now() - beginTimeMills);
    }
    // Initialization of storage space
    this.resetByteBuffer(msgStoreItemMemory, msgLen);
    // 1 TOTALSIZE
    this.msgStoreItemMemory.putInt(msgLen);
    // 2 MAGICCODE
    this.msgStoreItemMemory.putInt(CommitLog.MESSAGE_MAGIC_CODE);
    // 3 BODYCRC
    this.msgStoreItemMemory.putInt(msgInner.getBodyCRC());
    // 4 QUEUEID
    this.msgStoreItemMemory.putInt(msgInner.getQueueId());
    // 5 FLAG
    this.msgStoreItemMemory.putInt(msgInner.getFlag());
    // 6 QUEUEOFFSET
    this.msgStoreItemMemory.putLong(queueOffset);
    // 7 PHYSICALOFFSET
    this.msgStoreItemMemory.putLong(fileFromOffset + byteBuffer.position());
    // 8 SYSFLAG
    this.msgStoreItemMemory.putInt(msgInner.getSysFlag());
    // 9 BORNTIMESTAMP
    this.msgStoreItemMemory.putLong(msgInner.getBornTimestamp());
    // 10 BORNHOST
    this.resetByteBuffer(bornHostHolder, bornHostLength);
    this.msgStoreItemMemory.put(msgInner.getBornHostBytes(bornHostHolder));
    // 11 STORETIMESTAMP
    this.msgStoreItemMemory.putLong(msgInner.getStoreTimestamp());
    // 12 STOREHOSTADDRESS
    this.resetByteBuffer(storeHostHolder, storeHostLength);
    this.msgStoreItemMemory.put(msgInner.getStoreHostBytes(storeHostHolder));
    // 13 RECONSUMETIMES
    this.msgStoreItemMemory.putInt(msgInner.getReconsumeTimes());
    // 14 Prepared Transaction Offset
    this.msgStoreItemMemory.putLong(msgInner.getPreparedTransactionOffset());
    // 15 BODY
    this.msgStoreItemMemory.putInt(bodyLength);
    if (bodyLength > 0)
        this.msgStoreItemMemory.put(msgInner.getBody());
    // 16 TOPIC
    this.msgStoreItemMemory.put((byte) topicLength);
    this.msgStoreItemMemory.put(topicData);
    // 17 PROPERTIES
    this.msgStoreItemMemory.putShort((short) propertiesLength);
    if (propertiesLength > 0)
        this.msgStoreItemMemory.put(propertiesData);
    final long beginTimeMills = CommitLog.this.defaultMessageStore.now();
    // Write messages to the queue buffer
    byteBuffer.put(this.msgStoreItemMemory.array(), 0, msgLen);
    AppendMessageResult result = new AppendMessageResult(AppendMessageStatus.PUT_OK, wroteOffset, msgLen, msgId,
        msgInner.getStoreTimestamp(), queueOffset, CommitLog.this.defaultMessageStore.now() - beginTimeMills);
    switch (tranType) {
        case MessageSysFlag.TRANSACTION_PREPARED_TYPE:
        case MessageSysFlag.TRANSACTION_ROLLBACK_TYPE:
            break;
        case MessageSysFlag.TRANSACTION_NOT_TYPE:
        case MessageSysFlag.TRANSACTION_COMMIT_TYPE:
            // The next update ConsumeQueue information
            CommitLog.this.topicQueueTable.put(key, ++queueOffset);
            break;
        default:
            break;
    }
    return result;
}
```

## CommitLog#topicQueueTable

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

## StoreCheckpoint

```java
long storeTimestamp = CommitLog.this.mappedFileQueue.getStoreTimestamp();

CommitLog.this.defaultMessageStore.getStoreCheckpoint().setPhysicMsgTimestamp(storeTimestamp);
```

## submitReplicaRequest
