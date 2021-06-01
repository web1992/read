# Broker

## Broker 的启动

入口：`org.apache.rocketmq.broker.BrokerStartup`

## BrokerController init

[BrokerController 的构造方法](https://github.com/apache/rocketmq/blob/master/broker/src/main/java/org/apache/rocketmq/broker/BrokerController.java#L171)

| 字段                           | 描述 |
| ------------------------------ | ---- |
| brokerConfig                   |
| nettyServerConfig              |
| nettyClientConfig              |
| messageStoreConfig             |
| consumerOffsetManager          |
| topicConfigManager             |
| pullMessageProcessor           |
| pullRequestHoldService         |
| messageArrivingListener        |
| consumerIdsChangeListener      |
| consumerManager                |
| consumerFilterManager          |
| producerManager                |
| clientHousekeepingService      |
| broker2Client                  |
| subscriptionGroupManager       |
| brokerOuterAPI                 |
| filterServerManager            |
| slaveSynchronize               |
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
| messageStore.start()                                           |Broker 的存储服务
| remotingServer.start()                                         |启动 NettyRemotingServer 服务
| fastRemotingServer.start()                                     |启动 VipChannel
| fileWatchService.start()                                       |启动扫描 tls 配置的线程
| brokerOuterAPI.start()                                         |
| pullRequestHoldService.start()                                 |处理PullRequst首次没有拉取到消息，进行延迟拉取消息的线程
| clientHousekeepingService.start()                              |定期清除不活动的连接线程
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

- [fastRemotingServer VS remotingServer](http://www.tianshouzhi.com/api/tutorials/rocketmq/417)
