# RocketMQ 配置

## MessageStoreConfig

- ConsumerOffsetManager
- ConsumerFilterManager
- ScheduleMessageService
- SubscriptionGroupManager
- TopicConfigManager

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
