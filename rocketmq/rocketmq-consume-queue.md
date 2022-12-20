# ConsumeQueue

`org.apache.rocketmq.store.ConsumeQueue`

CommitLog 文件负责存储 message ,而 ConsumeQueue 文件则是 CommitLog 文件的索引文件，方法快速的从 CommitLog 中查找消息


![rocketmq-consumerqueue.drawio.svg](./images/rocketmq-consumerqueue.drawio.svg)


## ConsumeQueue 初始化

```java
public ConsumeQueue(
    final String topic,
    final int queueId,
    final String storePath,
    final int mappedFileSize,
    final DefaultMessageStore defaultMessageStore) {
    this.storePath = storePath;
    this.mappedFileSize = mappedFileSize;// mappedFileSize=6000000
    this.defaultMessageStore = defaultMessageStore;
    this.topic = topic;
    this.queueId = queueId;
    // this.storePath=/Users/zl/store/consumequeue
    String queueDir = this.storePath
        + File.separator + topic
        + File.separator + queueId;
    this.mappedFileQueue = new MappedFileQueue(queueDir, mappedFileSize, null);
    this.byteBufferIndex = ByteBuffer.allocate(CQ_STORE_UNIT_SIZE);
    if (defaultMessageStore.getMessageStoreConfig().isEnableConsumeQueueExt()) {
        this.consumeQueueExt = new ConsumeQueueExt(
            topic,
            queueId,
            StorePathConfigHelper.getStorePathConsumeQueueExt(defaultMessageStore.getMessageStoreConfig().getStorePathRootDir()),
            defaultMessageStore.getMessageStoreConfig().getMappedFileSizeConsumeQueueExt(),
            defaultMessageStore.getMessageStoreConfig().getBitMapLengthConsumeQueueExt()
        );
    }
}
```

`consumequeue` 在文件系统的存储目录结构如下：

```sh
# 查询 consumequeue 的文件结构
➜  store tree /Users/zl/store/consumequeue
/Users/zl/store/consumequeue
├── TopicTest
│   ├── 0
│   │   └── 00000000000000000000
│   ├── 1
│   │   └── 00000000000000000000
│   ├── 10
│   │   └── 00000000000000000000
│   ├── 11
│   │   └── 00000000000000000000
│   ├── 12
│   │   └── 00000000000000000000
│   ├── 13
│   │   └── 00000000000000000000
│   ├── 14
│   │   └── 00000000000000000000
│   ├── 15
│   │   └── 00000000000000000000
│   ├── 2
│   │   └── 00000000000000000000
│   ├── 3
│   │   └── 00000000000000000000
│   ├── 4
│   │   └── 00000000000000000000
│   ├── 5
│   │   └── 00000000000000000000
│   ├── 6
│   │   └── 00000000000000000000
│   ├── 7
│   │   └── 00000000000000000000
│   ├── 8
│   │   └── 00000000000000000000
│   └── 9
│       └── 00000000000000000000
├── TopicTest1234
│   ├── 0
│   │   └── 00000000000000000000
│   ├── 1
│   │   └── 00000000000000000000
│   ├── 2
│   │   └── 00000000000000000000
│   └── 3
│       └── 00000000000000000000
```

`topicQueueTable` 的更新

```java
// topicQueueTable 的 Key 和 Value
protected HashMap<String/* topic-queueid */, Long/* offset */> topicQueueTable = new HashMap<String, Long>(1024);

// DefaultAppendMessageCallback#doAppend
// The next update ConsumeQueue information
CommitLog.this.topicQueueTable.put(key, ++queueOffset);
```

`topicQueueTable` 的初始化

```java
// DefaultMessageStore#recoverTopicQueueTable
public void recoverTopicQueueTable() {
    HashMap<String/* topic-queueid */, Long/* offset */> table = new HashMap<String, Long>(1024);
    long minPhyOffset = this.commitLog.getMinOffset();
    for (ConcurrentMap<Integer, ConsumeQueue> maps : this.consumeQueueTable.values()) {
        for (ConsumeQueue logic : maps.values()) {
            String key = logic.getTopic() + "-" + logic.getQueueId();
            table.put(key, logic.getMaxOffsetInQueue());
            logic.correctMinOffset(minPhyOffset);
        }
    }
    this.commitLog.setTopicQueueTable(table);// 初始化 topicQueueTable
}
```

`findConsumeQueue`

```java
public ConsumeQueue findConsumeQueue(String topic, int queueId) {
    ConcurrentMap<Integer, ConsumeQueue> map = consumeQueueTable.get(topic);
    if (null == map) {
        ConcurrentMap<Integer, ConsumeQueue> newMap = new ConcurrentHashMap<Integer, ConsumeQueue>(128);
        ConcurrentMap<Integer, ConsumeQueue> oldMap = consumeQueueTable.putIfAbsent(topic, newMap);
        if (oldMap != null) {
            map = oldMap;
        } else {
            map = newMap;
        }
    }
    ConsumeQueue logic = map.get(queueId);
    if (null == logic) {
        ConsumeQueue newLogic = new ConsumeQueue(
            topic,
            queueId,
            StorePathConfigHelper.getStorePathConsumeQueue(this.messageStoreConfig.getStorePathRootDir()),
            this.getMessageStoreConfig().getMappedFileSizeConsumeQueue(),
            this);
        ConsumeQueue oldLogic = map.putIfAbsent(queueId, newLogic);
        if (oldLogic != null) {
            logic = oldLogic;
        } else {
            logic = newLogic;
        }
    }
    return logic;
}
```

- [RocketMQ ConsumerQueue](https://rocketmq.apache.org/rocketmq/how-to-support-more-queues-in-rocketmq/)
- [CommitLog 文件，ConsumerQueue 文件](https://www.cnblogs.com/zxporz/p/12336476.html)
