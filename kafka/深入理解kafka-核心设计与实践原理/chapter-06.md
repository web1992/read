# 第6章 深入服务端

- 协议设计
- 请求（Request）和响应（Response）
- 相同的协议请求头（RequestHeader）和不同结构的协议请求体（RequestBody）
- api_key、api_version、correlation_id 和client_id
- api_key API标识，比如 PRODUCE、FETCH 等分别表示发送消息和拉取消息的请求
- api_key=0，表示PRODUCE
- RecordAccumulator
- ProduceRequest/ProduceResponse 生产消息
- FetchRequest/FetchResponse 拉取消息
- follower 副本
- 从协议结构中就可以看出消息的写入和拉取消费都是细化到每一个分区层级的
- 时间轮
- 基于时间轮可以将插入和删除操作的时间复杂度都降为O（1）
- 基本时间跨度（tickMs）
- wheelSize
- 总体时间跨度（interval）=tickMs×wheelSize
- 时间轮还有一个表盘指针（currentTime），用来表示时间轮当前所处的时间，currentTime是tickMs的整数倍
- currentTime当前指向的时间格也属于到期部分，表示刚好到期
- TimingWheel TimerTaskList TimerTaskEntry TimerTask
- 定时器（SystemTimer）
- TimingWheel DelayQueue
- 层级时间轮
- 时间轮降级的操作
- DelayQueue会根据TimerTaskList对应的超时时间expiration来排序
- ExpiredOperationReaper 过期操作收割机
- DelayedProduce
- 延时拉取操作（DelayedFetch
- 其默认的事务隔离级别为read_uncommitted ，此外还有 read_committed
- 控制器（Kafka Controller）
- 控制器的纪元
- kafka-shutdown-hock
- bootstrap.servers

## 时间轮

JDK中Timer和DelayQueue的插入和删除操作的平均时间复杂度为O（nlogn）并不能满足Kafka的高性能要求，而基于时间轮可以将插入和删除操作的时间复杂度都降为O（1）。时间轮的应用并非Kafka独有，其应用场景还有很多，在Netty、Akka、Quartz、ZooKeeper等组件中都存在时间轮的踪影。

Kafka中的时间轮（TimingWheel）是一个存储定时任务的环形队列，底层采用数组实现，数组中的每个元素可以存放一个定时任务列表（TimerTaskList）。TimerTaskList是一个环形的双向链表，链表中的每一项表示的都是定时任务项（TimerTaskEntry），其中封装了真正的定时任务（TimerTask）。

Kafka 中的 TimingWheel 专门用来执行插入和删除 TimerTaskEntry的操作，而 DelayQueue 专门负责时间推进的任务。

## 延时操作

如果在使用生产者客户端发送消息的时候将 acks 参数设置为-1，那么就意味着需要等待ISR集合中的所有副本都确认收到消息之后才能正确地收到响应的结果，或者捕获超时异常。

## 控制器（Kafka Controller）

在 Kafka 集群中会有一个或多个 broker，其中有一个 broker 会被选举为控制器（Kafka Controller），它负责管理整个集群中所有分区和副本的状态。当某个分区的leader副本出现故障时，由控制器负责为该分区选举新的leader副本。当检测到某个分区的ISR集合发生变化时，由控制器负责通知所有broker更新其元数据信息。当使用kafka-topics.sh脚本为某个topic增加分区数量时，同样还是由控制器负责分区的重新分配。

具备控制器身份的broker需要比其他普通的broker多一份职责

- 监听分区相关的变化
- 监听主题相关的变化
- 监听broker相关的变化
- 从ZooKeeper中读取获取当前所有与主题、分区及broker有关的信息并进行相应的管理。
- 启动并管理分区状态机和副本状态机。
- 更新集群的元数据信息。
- 如果参数 auto.leader.rebalance.enable 设置为 true，则还会开启一个名为“auto-leader-rebalance-task”的定时任务来负责维护分区的优先副本的均衡。

在Kafka的早期版本中，并没有采用Kafka Controller这样一个概念来对分区和副本的状态进行管理，而是依赖于ZooKeeper，每个broker都会在ZooKeeper上为分区和副本注册大量的监听器（Watcher）。当分区或副本状态变化时，会唤醒很多不必要的监听器，这种严重依赖ZooKeeper 的设计会有脑裂、羊群效应，以及造成 ZooKeeper 过载的隐患（旧版的消费者客户端存在同样的问题，详细内容参考7.2.1节）。在目前的新版本的设计中，只有Kafka Controller在ZooKeeper上注册相应的监听器，其他的broker极少需要再监听ZooKeeper中的数据变化，这样省去了很多不必要的麻烦。不过每个broker还是会对/controller节点添加监听器，以此来监听此节点的数据变化（ControllerChangeHandler）。

