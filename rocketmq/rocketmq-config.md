# RocketMQ 配置

## MessageStoreConfig

`MessageStoreConfig` 和配置相关的实现类。

- ConsumerOffsetManager
- ConsumerFilterManager
- ScheduleMessageService
- SubscriptionGroupManager
- TopicConfigManager

## TopicConfigManager

`org.apache.rocketmq.broker.topic.TopicConfigManager` 负责 `RocketMQ` `Topic` 的创建

```java

private final ConcurrentMap<String, TopicConfig> topicConfigTable =
        new ConcurrentHashMap<String, TopicConfig>(1024);

// org.apache.rocketmq.broker.topic.TopicConfigManager 的构造方法
public TopicConfigManager(BrokerController brokerController) {
    this.brokerController = brokerController;
    {
        String topic = TopicValidator.RMQ_SYS_SELF_TEST_TOPIC;
        TopicConfig topicConfig = new TopicConfig(topic);
        TopicValidator.addSystemTopic(topic);
        topicConfig.setReadQueueNums(1);
        topicConfig.setWriteQueueNums(1);
        this.topicConfigTable.put(topicConfig.getTopicName(), topicConfig);
    }
    {
        if (this.brokerController.getBrokerConfig().isAutoCreateTopicEnable()) {
            String topic = TopicValidator.AUTO_CREATE_TOPIC_KEY_TOPIC;
            TopicConfig topicConfig = new TopicConfig(topic);
            TopicValidator.addSystemTopic(topic);
            topicConfig.setReadQueueNums(this.brokerController.getBrokerConfig()
                .getDefaultTopicQueueNums());
            topicConfig.setWriteQueueNums(this.brokerController.getBrokerConfig()
                .getDefaultTopicQueueNums());
            int perm = PermName.PERM_INHERIT | PermName.PERM_READ | PermName.PERM_WRITE;
            topicConfig.setPerm(perm);
            this.topicConfigTable.put(topicConfig.getTopicName(), topicConfig);
        }
    }
    {
        String topic = TopicValidator.RMQ_SYS_BENCHMARK_TOPIC;
        TopicConfig topicConfig = new TopicConfig(topic);
        TopicValidator.addSystemTopic(topic);
        topicConfig.setReadQueueNums(1024);
        topicConfig.setWriteQueueNums(1024);
        this.topicConfigTable.put(topicConfig.getTopicName(), topicConfig);
    }
    {
        String topic = this.brokerController.getBrokerConfig().getBrokerClusterName();
        TopicConfig topicConfig = new TopicConfig(topic);
        TopicValidator.addSystemTopic(topic);
        int perm = PermName.PERM_INHERIT;
        if (this.brokerController.getBrokerConfig().isClusterTopicEnable()) {
            perm |= PermName.PERM_READ | PermName.PERM_WRITE;
        }
        topicConfig.setPerm(perm);
        this.topicConfigTable.put(topicConfig.getTopicName(), topicConfig);
    }
    {
        String topic = this.brokerController.getBrokerConfig().getBrokerName();
        TopicConfig topicConfig = new TopicConfig(topic);
        TopicValidator.addSystemTopic(topic);
        int perm = PermName.PERM_INHERIT;
        if (this.brokerController.getBrokerConfig().isBrokerTopicEnable()) {
            perm |= PermName.PERM_READ | PermName.PERM_WRITE;
        }
        topicConfig.setReadQueueNums(1);
        topicConfig.setWriteQueueNums(1);
        topicConfig.setPerm(perm);
        this.topicConfigTable.put(topicConfig.getTopicName(), topicConfig);
    }
    {
        String topic = TopicValidator.RMQ_SYS_OFFSET_MOVED_EVENT;
        TopicConfig topicConfig = new TopicConfig(topic);
        TopicValidator.addSystemTopic(topic);
        topicConfig.setReadQueueNums(1);
        topicConfig.setWriteQueueNums(1);
        this.topicConfigTable.put(topicConfig.getTopicName(), topicConfig);
    }
    {
        String topic = TopicValidator.RMQ_SYS_SCHEDULE_TOPIC;
        TopicConfig topicConfig = new TopicConfig(topic);
        TopicValidator.addSystemTopic(topic);
        topicConfig.setReadQueueNums(SCHEDULE_TOPIC_QUEUE_NUM);
        topicConfig.setWriteQueueNums(SCHEDULE_TOPIC_QUEUE_NUM);
        this.topicConfigTable.put(topicConfig.getTopicName(), topicConfig);
    }
    {
        if (this.brokerController.getBrokerConfig().isTraceTopicEnable()) {
            String topic = this.brokerController.getBrokerConfig().getMsgTraceTopicName();
            TopicConfig topicConfig = new TopicConfig(topic);
            TopicValidator.addSystemTopic(topic);
            topicConfig.setReadQueueNums(1);
            topicConfig.setWriteQueueNums(1);
            this.topicConfigTable.put(topicConfig.getTopicName(), topicConfig);
        }
    }
    {
        String topic = this.brokerController.getBrokerConfig().getBrokerClusterName() + "_" + MixAll.REPLY_TOPIC_POSTFIX;
        TopicConfig topicConfig = new TopicConfig(topic);
        TopicValidator.addSystemTopic(topic);
        topicConfig.setReadQueueNums(1);
        topicConfig.setWriteQueueNums(1);
        this.topicConfigTable.put(topicConfig.getTopicName(), topicConfig);
    }
}
```

| TOPIC名称           | 描述                                                                                                               |
| ------------------- | ------------------------------------------------------------------------------------------------------------------ |
| SELF_TEST_TOPIC     |
| TBW102              |
| BenchmarkTest       |
| DefaultCluster      | `String topic = this.brokerController.getBrokerConfig().getBrokerClusterName();`                                   |
| BrokerName          | `String topic = this.brokerController.getBrokerConfig().getBrokerName()`                                           |
| OFFSET_MOVED_EVENT  |
| SCHEDULE_TOPIC_XXXX |
| RMQ_SYS_TRACE_TOPIC | `String topic = this.brokerController.getBrokerConfig().getMsgTraceTopicName()`                                    |
| REPLY_TOPIC         | `String topic = this.brokerController.getBrokerConfig().getBrokerClusterName() + "_" + MixAll.REPLY_TOPIC_POSTFIX` |

## ConsumerOffsetManager

`ConsumerOffsetManager` 用来管理消费者的 `offset` ，下面是核心方法。

```java
// 核心方法 obj -> json
public String encode() {
    return this.encode(false);
}
// 获取配置文件的路基
@Override
public String configFilePath() {
    return BrokerPathConfigHelper.getConsumerOffsetPath(this.brokerController.getMessageStoreConfig().getStorePathRootDir());
}
// json -> obj 对象
@Override
public void decode(String jsonString) {
    if (jsonString != null) {
        ConsumerOffsetManager obj = RemotingSerializable.fromJson(jsonString, ConsumerOffsetManager.class);
        if (obj != null) {
            this.offsetTable = obj.offsetTable;
        }
    }
}
// obj -> json
public String encode(final boolean prettyFormat) {
    return RemotingSerializable.toJson(this, prettyFormat);
}
```

## 配置文件的持久化

`persist`

```java
// ConfigManager
public abstract String configFilePath();

// ConfigManager#persist
public synchronized void persist() {
    String jsonString = this.encode(true);// obj -> json
    if (jsonString != null) {
        String fileName = this.configFilePath();// 获取文件路基
        try {
            // 此方法把 josn 存储到文件系统 
            MixAll.string2File(jsonString, fileName);
        } catch (IOException e) {
            log.error("persist file " + fileName + " exception", e);
        }
    }
}
```

`ScheduleMessageService` 会启动定时任务执行下面的方法，进行值内存的持久化操作

```java
if (started.get()) ScheduleMessageService.this.persist();
```

## ScheduleMessageService

`org.apache.rocketmq.store.schedule.ScheduleMessageService`

```java
// 会在 DefaultMessageStore 中启动 
 @Override
 public void handleScheduleMessageService(final BrokerRole brokerRole) {
     if (this.scheduleMessageService != null) {
         if (brokerRole == BrokerRole.SLAVE) {
             this.scheduleMessageService.shutdown();
         } else {
             // 启动 ScheduleMessageService
             this.scheduleMessageService.start();
         }
     }

 }
```
