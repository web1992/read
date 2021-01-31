# RocketMQ Store

## MQ 请求处理流程

```java
NettyDecoder ->
    NettyServerHandler -> channelRead0 -> processMessageReceived -> processRequestCommand
        -> NettyRemotingAbstract -> ExecutorService
            -> AsyncNettyRequestProcessor -> asyncProcessRequest
                -> SendMessageProcessor -> asyncProcessRequest -> asyncSendMessage
                    -> DefaultMessageStore#asyncPutMessage
                        -> CommitLog#asyncPutMessage
                            -> MappedFile#appendMessage
```

上面的流程的核心思想就是把网络请求通过 `ExecutorService` 进行异步化处理。

![rocket-netty-async.png](./images/rocket-netty-async.png)

## SendMessageProcessor

```java
if (transFlag != null && Boolean.parseBoolean(transFlag)) {
    if (this.brokerController.getBrokerConfig().isRejectTransactionMessage()) {
        response.setCode(ResponseCode.NO_PERMISSION);
        response.setRemark(
                "the broker[" + this.brokerController.getBrokerConfig().getBrokerIP1()
                        + "] sending transaction message is forbidden");
        return CompletableFuture.completedFuture(response);
    }// 事务消息
    putMessageResult = this.brokerController.getTransactionalMessageService().asyncPrepareMessage(msgInner);
} else {// 非事务消息
    putMessageResult = this.brokerController.getMessageStore().asyncPutMessage(msgInner);
}
```

## DefaultMessageStore

- 检查 `Topic` 长度 `Byte.MAX_VALUE`
- 检查 `Properties` 长度 `Short.MAX_VALUE`

## StoreStatsService

## CommitLog

```java
public class CommitLog {
    // Message's MAGIC CODE daa320a7
    public final static int MESSAGE_MAGIC_CODE = -626843481;
    protected static final InternalLogger log = InternalLoggerFactory.getLogger(LoggerName.STORE_LOGGER_NAME);
    // End of file empty MAGIC CODE cbd43194
    protected final static int BLANK_MAGIC_CODE = -875286124;
    protected final MappedFileQueue mappedFileQueue;
    protected final DefaultMessageStore defaultMessageStore;
    private final FlushCommitLogService flushCommitLogService;

    //If TransientStorePool enabled, we must flush message to FileChannel at fixed periods
    private final FlushCommitLogService commitLogService;

    private final AppendMessageCallback appendMessageCallback;
    private final ThreadLocal<MessageExtBatchEncoder> batchEncoderThreadLocal;
    protected HashMap<String/* topic-queueid */, Long/* offset */> topicQueueTable = new HashMap<String, Long>(1024);
    protected volatile long confirmOffset = -1L;

    private volatile long beginTimeInLock = 0;

    protected final PutMessageLock putMessageLock;
    // 省略其他代码
}
```

### CommitLog#asyncPutMessage

### CommitLog#submitFlushRequest

### DefaultAppendMessageCallback

```java
DefaultAppendMessageCallback implements AppendMessageCallback {} 
```

## MappedFile

```java
final int tranType = MessageSysFlag.getTransactionValue(msg.getSysFlag());
 if (tranType == MessageSysFlag.TRANSACTION_NOT_TYPE
         || tranType == MessageSysFlag.TRANSACTION_COMMIT_TYPE) {
     // Delay Delivery
     if (msg.getDelayTimeLevel() > 0) {
         if (msg.getDelayTimeLevel() > this.defaultMessageStore.getScheduleMessageService().getMaxDelayLevel()) {
             msg.setDelayTimeLevel(this.defaultMessageStore.getScheduleMessageService().getMaxDelayLevel());
         }
         topic = TopicValidator.RMQ_SYS_SCHEDULE_TOPIC;
         queueId = ScheduleMessageService.delayLevel2QueueId(msg.getDelayTimeLevel());
         // Backup real topic, queueId
         MessageAccessor.putProperty(msg, MessageConst.PROPERTY_REAL_TOPIC, msg.getTopic());
         MessageAccessor.putProperty(msg, MessageConst.PROPERTY_REAL_QUEUE_ID, String.valueOf(msg.getQueueId()));
         msg.setPropertiesString(MessageDecoder.messageProperties2String(msg.getProperties()));
         msg.setTopic(topic);
         msg.setQueueId(queueId);
     }
 }
```

## Index File

## store dir

abort
checkpoint
commitlog
config
consumequeue
index  
lock

```sh
# 在 store 目录下面执行
tree
```

输出

```sh
.
├── abort
├── checkpoint
├── commitlog
│   └── 00000000000000000000
├── config
│   ├── consumerFilter.json
│   ├── consumerFilter.json.bak
│   ├── consumerOffset.json
│   ├── consumerOffset.json.bak
│   ├── delayOffset.json
│   ├── delayOffset.json.bak
│   ├── subscriptionGroup.json
│   ├── subscriptionGroup.json.bak
│   ├── topics.json
│   └── topics.json.bak
├── consumequeue
│   └── TopicTest
│       ├── 0
│       │   └── 00000000000000000000
│       ├── 1
│       │   └── 00000000000000000000
│       ├── 10
│       │   └── 00000000000000000000
│       ├── 11
│       │   └── 00000000000000000000
│       ├── 12
│       │   └── 00000000000000000000
│       ├── 13
│       │   └── 00000000000000000000
│       ├── 14
│       │   └── 00000000000000000000
│       ├── 15
│       │   └── 00000000000000000000
│       ├── 2
│       │   └── 00000000000000000000
│       ├── 3
│       │   └── 00000000000000000000
│       ├── 4
│       │   └── 00000000000000000000
│       ├── 5
│       │   └── 00000000000000000000
│       ├── 6
│       │   └── 00000000000000000000
│       ├── 7
│       │   └── 00000000000000000000
│       ├── 8
│       │   └── 00000000000000000000
│       └── 9
│           └── 00000000000000000000
├── index
│   └── 20200826182922776
└── lock

21 directories, 31 files

```
