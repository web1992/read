# Broker

## Broker 的启动

入口：`org.apache.rocketmq.broker.BrokerStartup`

## BrokerController init

[BrokerController 的构造方法](https://github.com/apache/rocketmq/blob/master/broker/src/main/java/org/apache/rocketmq/broker/BrokerController.java#L171)

| 字段                           | 描述                                                                       |
| ------------------------------ | -------------------------------------------------------------------------- |
| brokerConfig                   | Broker 的配置                                                              |
| nettyServerConfig              | Broker Netty服务端的配置                                                   |
| nettyClientConfig              | Broker 与NameServer等交互的时候，角色是Client,这是Broker角色是Client的配置 |
| messageStoreConfig             | Broker 存储相关的配置                                                      |
| consumerOffsetManager          | 消息消费位置管理的Manager                                                  |
| topicConfigManager             | 消息的路由信息管理Mnager                                                   |
| pullMessageProcessor           | 处理Consumer拉取消息的处理器
| pullRequestHoldService         | 如果Consumer执行pullRequest首次没有拉取到消息，使用此类暂存，之后再拉取消息
| messageArrivingListener        | 配合pullRequestHoldService一起使用
| consumerIdsChangeListener      |
| consumerManager                | 管理所有Consumer的Manager                                                  |
| consumerFilterManager          | 管理消息过滤的Manager                                                      |
| producerManager                | 管理所有Producer的Manager                                                  |
| clientHousekeepingService      | 定期清除过期失效的Client连接
| broker2Client                  | 支持Borker调用Producer和Consumer的TCP交互
| subscriptionGroupManager       |
| brokerOuterAPI                 |
| filterServerManager            |
| slaveSynchronize               | SLAVE 数据同步
| sendThreadPoolQueue            |
| pullThreadPoolQueue            |
| replyThreadPoolQueue           |
| queryThreadPoolQueue           |
| clientManagerThreadPoolQueue   |
| consumerManagerThreadPoolQueue |
| heartbeatThreadPoolQueue       |
| endTransactionThreadPoolQueue  |
| brokerStatsManager             |
| brokerFastFailure              |
| configuration                  |

## BrokerController#initialize

[initialize 方法源码](https://github.com/apache/rocketmq/blob/master/broker/src/main/java/org/apache/rocketmq/broker/BrokerController.java#L234)

| 初始化的内容                                                            | 描述 |
| ----------------------------------------------------------------------- | ---- |
| topicConfigManager 信息加载                                             |
| consumerOffsetManager 的加载                                            |
| subscriptionGroupManager 的加载                                         |
| consumerFilterManager 的加载                                            |
| messageStore 的创建和加载                                               |
| remotingServer 的创建                                                   |
| fastRemotingServer 的创建                                               |
| sendMessageExecutor 线程池的创建                                        |
| pullMessageExecutor 线程池的创建                                        |
| replyMessageExecutor                                                    |
| queryMessageExecutor                                                    |
| adminBrokerExecutor                                                     |
| clientManageExecutor                                                    |
| heartbeatExecutor                                                       |
| endTransactionExecutor                                                  |
| consumerManageExecutor                                                  |
| registerProcessor                                                       |
| 提交 BrokerController.this.getBrokerStats().record() 任务               |
| 提交 BrokerController.this.consumerOffsetManager.persist() 任务         |
| 提交 BrokerController.this.consumerFilterManager.persist() 任务         |
| 提交 BrokerController.this.protectBroker() 任务                         |
| 提交 BrokerController.this.printWaterMark() 任务                        |
| 提交 BrokerController.this.getMessageStore().dispatchBehindBytes() 任务 |
| 提交 BrokerController.this.brokerOuterAPI.fetchNameServerAddr() 任务    |
| 提交 BrokerController.this.printMasterAndSlaveDiff(); 任务              |
| 提交 loadSslContext 任务                                                |
| initialTransaction();                                                   |
| initialAcl();                                                           |
| initialRpcHooks();                                                      |

## BrokerController#start

[start 方法源码](https://github.com/apache/rocketmq/blob/master/broker/src/main/java/org/apache/rocketmq/broker/BrokerController.java#L851)

| 启动的服务                                                     | 描述                                                                                  |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| messageStore.start()                                           | Broker 的存储服务                                                                     |
| remotingServer.start()                                         | 启动 NettyRemotingServer 服务                                                         |
| fastRemotingServer.start()                                     | 启动 VipChannel                                                                       |
| fileWatchService.start()                                       | 启动扫描 tls 配置的线程                                                               |
| brokerOuterAPI.start()                                         |
| pullRequestHoldService.start()                                 | 处理PullRequst首次没有拉取到消息，进行延迟拉取消息的线程                              |
| clientHousekeepingService.start()                              | 定期清除不活动的连接线程                                                              |
| filterServerManager.start()                                    |
| startProcessorByHa                                             | 如果不是 SLAVE ，启动 transactionalMessageCheckService 服务                           |
| handleSlaveSynchronize                                         | 如果是SLAVE 启动 BrokerController.this.slaveSynchronize.syncAll(); 任务。不是则不启动 |
| registerBrokerAll                                              | 注册Borker 的路由信息到NameServer                                                     |
| registerBrokerAll(true, false, brokerConfig.isForceRegister()) | 提交 注册Borker 的路由信息到NameServer 的定时任务                                     |
| brokerStatsManager.start()                                     | NOP                                                                                   |
| brokerFastFailure.start()                                      | 快速失败服务启动,启动 cleanExpiredRequest(); 任务                                     |

### cleanExpiredRequest

`cleanExpiredRequest` 会检测服务是否是繁忙状态，如果是则从sendThreadPoolQueue 队列中取Reuest，返回 RemotingSysResponseCode.SYSTEM_BUSY 状态，这样可以避免Broker内存溢出宕机。

## Links

- [fastRemotingServer(VipChannel) VS remotingServer](http://www.tianshouzhi.com/api/tutorials/rocketmq/417)
