# NameServer

NameServer 的主要目的是注册 Broker 信息，方便 Producer 和 Consumer 发现可用的 Broker。进行消息的发送和消费。

## 启动

`NamesrvController` 是负责 NameServer 启动的主要实现类。

主要逻辑都在 [NamesrvController#initialize](https://github.com/apache/rocketmq/blob/master/namesrv/src/main/java/org/apache/rocketmq/namesrv/NamesrvController.java#L76) 方法中，而我们要关注的核心是执行 `scanNotActiveBroker` 方法的定时任务

```java
// initialize 的主要作用
// 1. 使用 kvConfigManager 加载配置
// 2. remotingServer Netty TCP 服务
// 3. remotingExecutor netty 的线程池服务
// 4. registerProcessor 注册 RemotingCommand 处理器,用来处理CMD命令
// 5. 启动扫描 Broker 的线程
// 6. 启动定期打印 kv config 的线程
// 7. 启动扫描 Tls 配置的线程
public boolean initialize() {
 // ...
}
```

## scanNotActiveBroker

```java
// 扫描不活动的Broker,从brokerLiveTable中移除
public void scanNotActiveBroker() {
    Iterator<Entry<String, BrokerLiveInfo>> it = this.brokerLiveTable.entrySet().iterator();
    while (it.hasNext()) {
        Entry<String, BrokerLiveInfo> next = it.next();
        long last = next.getValue().getLastUpdateTimestamp();
        if ((last + BROKER_CHANNEL_EXPIRED_TIME) < System.currentTimeMillis()) {
            RemotingUtil.closeChannel(next.getValue().getChannel());
            it.remove();
            log.warn("The broker channel expired, {} {}ms", next.getKey(), BROKER_CHANNEL_EXPIRED_TIME);
            // 执行此方法移除 Broker信息，路由信息等等。
            this.onChannelDestroy(next.getKey(), next.getValue().getChannel());
        }
    }
}
```

## DefaultRequestProcessor

`org.apache.rocketmq.namesrv.processor.DefaultRequestProcessor` 的主要作用是处理 `RemotingCommand`，因此通过 `DefaultRequestProcessor` 就可以知道NameServer的作用包含哪些。

[DefaultRequestProcessor#processRequest 代码片段](https://github.com/apache/rocketmq/blob/master/namesrv/src/main/java/org/apache/rocketmq/namesrv/processor/DefaultRequestProcessor.java#L71)

下面的的代码片段中有`19`个Case,每个Case都处理不同的业务。

核心的 `RequestCode`:

- REGISTER_BROKER
- UNREGISTER_BROKER
- GET_ROUTEINFO_BY_TOPIC

| RequestCode                        | 描述                   |
| ---------------------------------- | ---------------------- |
| PUT_KV_CONFIG                      |
| GET_KV_CONFIG                      |
| DELETE_KV_CONFIG                   |
| QUERY_DATA_VERSION                 |
| REGISTER_BROKER                    | 注册 Broker            |
| UNREGISTER_BROKER                  | 取消注册 Broker        |
| GET_ROUTEINFO_BY_TOPIC             | 根据Topic 查询路由信息 |
| GET_BROKER_CLUSTER_INFO            |
| WIPE_WRITE_PERM_OF_BROKER          |
| GET_ALL_TOPIC_LIST_FROM_NAMESERVER |
| DELETE_TOPIC_IN_NAMESRV            |
| GET_KVLIST_BY_NAMESPACE            |
| GET_TOPICS_BY_CLUSTER              |
| GET_SYSTEM_TOPIC_LIST_FROM_NS      |
| GET_UNIT_TOPIC_LIST                |
| GET_HAS_UNIT_SUB_TOPIC_LIST        |
| GET_HAS_UNIT_SUB_UNUNIT_TOPIC_LIST |
| UPDATE_NAMESRV_CONFIG              |
| GET_NAMESRV_CONFIG                 |

## registerBroker

Broker 的注册

```java
// IDEA: DefaultRequestProcessor#registerBroker:300
RegisterBrokerResult result = this.namesrvController.getRouteInfoManager().registerBroker(
    requestHeader.getClusterName(),
    requestHeader.getBrokerAddr(),
    requestHeader.getBrokerName(),
    requestHeader.getBrokerId(),
    requestHeader.getHaServerAddr(),
    topicConfigWrapper,
    null,
    ctx.channel()
);
```

## unregisterBroker

Broker 的取消注册

## RouteInfoManager

RouteInfoManager 的主要作用就是存储Broker集群相关的信息。从下面的变量中就可以知道，NameServer中存储了那些信息。

![rocketmq-nameserver-info.png](./images/rocketmq-nameserver-info.png)

```java
// RouteInfoManager 的成员变量
public class RouteInfoManager {
    // 超时时间
    private final static long BROKER_CHANNEL_EXPIRED_TIME = 1000 * 60 * 2;

    private final HashMap<String/* topic */, List<QueueData>> topicQueueTable;
    private final HashMap<String/* brokerName */, BrokerData> brokerAddrTable;
    private final HashMap<String/* clusterName */, Set<String/* brokerName */>> clusterAddrTable;
    private final HashMap<String/* brokerAddr */, BrokerLiveInfo> brokerLiveTable;
    private final HashMap<String/* brokerAddr */, List<String>/* Filter Server */> filterServerTable;
}

public class QueueData implements Comparable<QueueData> {
    private String brokerName;
    private int readQueueNums;
    private int writeQueueNums;
    private int perm;
    private int topicSynFlag;
}
public class BrokerData implements Comparable<BrokerData> {
    private String cluster;
    private String brokerName;
    private HashMap<Long/* brokerId */, String/* broker address */> brokerAddrs;

    private final Random random = new Random();
}

class BrokerLiveInfo {
    private long lastUpdateTimestamp;
    private DataVersion dataVersion;
    private Channel channel;
    private String haServerAddr;
}
```

| 信息              | 描述                                                        |
| ----------------- | ----------------------------------------------------------- |
| topicQueueTable   | topic下面的queue的信息                                      |
| brokerAddrTable   | brokerName + cluster + brokerId + broker address 的集群信息 |
| clusterAddrTable  | clusterName + brokerName 的映射关系                         |
| brokerLiveTable   | brokerAddr + Channel TCP 连接信息                           |
| filterServerTable | brokerAddr + Filter Server 的映射信息                       |

这里说下 brokerAddrTable 列表这个变量。这里面存储的是 BrokerData ，而BrokerData 里面维护了 brokerId + broker address 的映射关系

brokerAddrs 是一个 map,里面存储了名称相同的 brokerName 的 brokerId + broker address。

因此在执行`unregisterBroker`操作的时候，会根据 brokerName 拿到BrokerData的map，在根据brokerId 去移除具体的Broker信息。

看下RocketMQ集群模式下的相关配置,[2m-2s-sync的配置](https://github.com/apache/rocketmq/tree/master/distribution/conf/2m-2s-sync)

```properties
# cat broker-a.properties
brokerClusterName=DefaultCluster
brokerName=broker-a
brokerId=0
deleteWhen=04
fileReservedTime=48
brokerRole=SYNC_MASTER
flushDiskType=ASYNC_FLUSH

# broker-a-s.properties
brokerClusterName=DefaultCluster
brokerName=broker-a
brokerId=1
deleteWhen=04
fileReservedTime=48
brokerRole=SLAVE
flushDiskType=ASYNC_FLUSH

# broker-b.properties
brokerClusterName=DefaultCluster
brokerName=broker-b
brokerId=0
deleteWhen=04
fileReservedTime=48
brokerRole=SYNC_MASTER
flushDiskType=ASYNC_FLUSH

# broker-b-s.properties
brokerClusterName=DefaultCluster
brokerName=broker-b
brokerId=1
deleteWhen=04
fileReservedTime=48
brokerRole=SLAVE
flushDiskType=ASYNC_FLUSH
```

可见上述配置 `Master`&`Slave` 的配置中的`brokerName`是一样的。

## getRouteInfoByTopic

路由信息的查询，入口在 [DefaultRequestProcessor#getRouteInfoByTopic](https://github.com/apache/rocketmq/blob/master/namesrv/src/main/java/org/apache/rocketmq/namesrv/processor/DefaultRequestProcessor.java#L338),具体的实现在中 [RouteInfoManager#pickupTopicRouteData](https://github.com/apache/rocketmq/blob/aaa92a2e53d773c7f1d9e9f25e41709f6948fa83/namesrv/src/main/java/org/apache/rocketmq/namesrv/routeinfo/RouteInfoManager.java#L374)

此处的实现逻辑比较简单。不在赘述。下面看下伪代码：

```java
// init 初始化
TopicRouteData topicRouteData = new TopicRouteData();
topicRouteData.setBrokerDatas(brokerDataList);
topicRouteData.setFilterServerTable(filterServerMap);
// ... 
// 根据 topic 查询QueueData
List<QueueData> queueDataList = this.topicQueueTable.get(topic);
// 获取所有的Broker 存入 brokerNameSet
// 根据 brokerName 查询 BrokerData
BrokerData brokerData = this.brokerAddrTable.get(brokerName);
// 填充 brokerData
brokerDataList.add(brokerDataClone);
// 填充 filterServer
filterServerMap.put(brokerAddr, filterServerList);
// 返回 topicRouteData
return topicRouteData;
```

## Links

- [rocketmq-remoting-command.md](rocketmq-remoting-command.md)
