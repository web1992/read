# 第7章 深入客户端

- 设置消费者与订阅主题之间的分区分配策略
- RangeAssignor
- RoundRobinAssignor
- StickyAssignor 黏性
- PartitionAssignor
- 再均衡的原理
- ConsumerCoordinator与GroupCoordinator
- 消费组的leader
- 消费者所支持的分配策略
- 消费组元数据信息
- 幂等
- 事务
- enable.idempotence=true
- retries、acks、max.in.flight.requests.per.connection
- producer id（以下简称PID）和序列号（sequence number）
- ＜PID，分区＞
- transactionalId
- isolation.level
- consume-transform-produce 
- __transaction_state
- 新的生产者启动后具有相同transactionalId的旧生产者能够立即失效
- isolation.level = read_uncommitted/read_committed
- 控制消息（ControlBatch）
- 事务协调器（TransactionCoordinator）来负责处理事务

## 消费分区

按照Kafka默认的消费逻辑设定，一个分区只能被同一个消费组（ConsumerGroup）内的一个消费者消费。但这一设定不是绝对的，我们可以通过自定义分区分配策略使一个分区可以分配给多个消费者消费。

## 消费广播

考虑一种极端情况，同一消费组内的任意消费者都可以消费订阅主题的所有分区，从而实现了一种“组内广播（消费）”的功能。

针对上述这种情况，如果要真正实现组内广播，则需要自己保存每个消费者的消费位移。笔者的实践经验是，可以通过将消费位移保存到本地文件或数据库中等方法来实现组内广播的位移提交。


## 消息消费Zookeeper 实现

每个消费者在启动时都会在/consumers/＜group＞/ids 和/brokers/ids 路径上注册一个监听器。当/consumers/＜group＞/ids路径下的子节点发生变化时，表示消费组中的消费者发生了变化；当/brokers/ids路径下的子节点发生变化时，表示broker出现了增减。这样通过ZooKeeper所提供的Watcher，每个消费者就可以监听消费组和Kafka集群的状态了。

这种方式下每个消费者对ZooKeeper的相关路径分别进行监听，当触发再均衡操作时，一个消费组下的所有消费者会同时进行再均衡操作，而消费者之间并不知道彼此操作的结果，这样可能导致Kafka工作在一个不正确的状态。与此同时，这种严重依赖于ZooKeeper集群的做法还有两个比较严重的问题。

（1）羊群效应（Herd Effect）：所谓的羊群效应是指ZooKeeper中一个被监听的节点变化，大量的 Watcher 通知被发送到客户端，导致在通知期间的其他操作延迟，也有可能发生类似死锁的情况。

（2）脑裂问题（Split Brain）：消费者进行再均衡操作时每个消费者都与ZooKeeper进行通信以判断消费者或broker变化的情况，由于ZooKeeper本身的特性，可能导致在同一时刻各个消费者获取的状态不一致，这样会导致异常问题发生。

## 再均衡的原理

ConsumerCoordinator与GroupCoordinator之间最重要的职责就是负责执行消费者再均衡的操作，包括前面提及的分区分配的工作也是在再均衡期间完成的。就目前而言，一共有如下几种情形会触发再均衡的操作：

- 有新的消费者加入消费组。
- 有消费者宕机下线。消费者并不一定需要真正下线，例如遇到长时间的 GC、网络延迟导致消费者长时间未向GroupCoordinator发送心跳等情况时，GroupCoordinator会认为消费者已经下线。
- 有消费者主动退出消费组（发送 LeaveGroupRequest 请求）。比如客户端调用了unsubscrible（）方法取消对某些主题的订阅。
- 消费组所对应的GroupCoorinator节点发生了变更。
- 消费组内所订阅的任一主题或者主题的分区数量发生变化。

## consumer_offsets

消费者客户端提交的消费位移会保存在Kafka的__consumer_offsets主题中


## 消息传输保障

一般而言，消息中间件的消息传输保障有3个层级，分别如下。
-（1）at most once：至多一次。消息可能会丢失，但绝对不会重复传输。
-（2）at least once：最少一次。消息绝不会丢失，但可能会重复传输。
-（3）exactly once：恰好一次。每条消息肯定会被传输一次且仅传输一次。

kafka 的消息传输保障机制非常直观。当生产者向 Kafka 发送消息时，一旦消息被成功提交到日志文件，由于多副本机制的存在，这条消息就不会丢失。如果生产者发送消息到 Kafka之后，遇到了网络问题而造成通信中断，那么生产者就无法判断该消息是否已经提交。虽然Kafka无法确定网络故障期间发生了什么，但生产者可以进行多次重试来确保消息已经写入 Kafka，这个重试的过程中有可能会造成消息的重复写入，所以这里 Kafka 提供的消息传输保障为 at least once。

对消费者而言，消费者处理消息和提交消费位移的顺序在很大程度上决定了消费者提供哪一种消息传输保障。如果消费者在拉取完消息之后，应用逻辑先处理消息后提交消费位移，那么在消息处理之后且在位移提交之前消费者宕机了，待它重新上线之后，会从上一次位移提交的位置拉取，这样就出现了重复消费，因为有部分消息已经处理过了只是还没来得及提交消费位移，此时就对应`at least once`。如果消费者在拉完消息之后，应用逻辑先提交消费位移后进行消息处理，那么在位移提交之后且在消息处理完成之前消费者宕机了，待它重新上线之后，会从已经提交的位移处开始重新消费，但之前尚有部分消息未进行消费，如此就会发生消息丢失，此时就对应`at most once`。

Kafka从0.11.0.0版本开始引入了幂等和事务这两个特性，以此来实现EOS（exactly once semantics，精确一次处理语义）。

## 生产者的幂等性

为了实现生产者的幂等性，Kafka为此引入了producer id（以下简称PID）和序列号（sequence number）这两个概念，这两个概念其实在 5.2.5 节中就讲过，分别对应 v2 版的日志格式中RecordBatch的producer id和first seqence这两个字段（参考图5-7）。每个新的生产者实例在初始化的时候都会被分配一个PID，这个PID对用户而言是完全透明的。对于每个PID，消息发送到的每一个分区都有对应的序列号，这些序列号从0开始单调递增。生产者每发送一条消息就会将＜PID，分区＞对应的序列号的值加1。

broker端会在内存中为每一对＜PID，分区＞维护一个序列号。对于收到的每一条消息，只有当它的序列号的值（SN_new）比broker端中维护的对应的序列号的值（SN_old）大1（即SN_new=SN_old+1）时，broker才会接收它。如果SN_new＜SN_old+1，那么说明消息被重复写入，broker可以直接将其丢弃。如果SN_new＞SN_old+1，那么说明中间有数据尚未写入，出现了乱序，暗示可能有消息丢失，对应的生产者会抛出OutOfOrderSequenceException，这个异常是一个严重的异常，后续的诸如 send（）、beginTransaction（）、commitTransaction（）等方法的调用都会抛出IllegalStateException的异常。

引入序列号来实现幂等也只是针对每一对＜PID，分区＞而言的，也就是说，Kafka的幂等只能保证单个生产者会话（session）中单分区的幂等。

## 事务

幂等性并不能跨多个分区运作，而事务[1]可以弥补这个缺陷。事务可以保证对多个分区写入操作的原子性。操作的原子性是指多个操作要么全部成功，要么全部失败，不存在部分成功、部分失败的可能。

对流式应用（Stream Processing Applications）而言，一个典型的应用模式为“consume-transform-produce”。在这种模式下消费和生产并存：应用程序从某个主题中消费消息，然后经过一系列转换后写入另一个主题，消费者可能在提交消费位移的过程中出现问题而导致重复消费，也有可能生产者重复生产消息。Kafka 中的事务可以使应用程序将`消费消息、生产消息、提交消费位移`当作`原子操作`来处理，同时成功或失败，即使该生产或消费会跨多个分区。

为了实现事务，应用程序必须提供唯一的 transactionalId，这个 transactionalId 通过客户端参数transactional.id来显式设置

从生产者的角度分析，通过事务，Kafka 可以保证跨生产者会话的消息幂等发送，以及跨生产者会话的事务恢复。前者表示具有相同 transactionalId 的新生产者实例被创建且工作的时候，旧的且拥有相同transactionalId的生产者实例将不再工作。后者指当某个生产者实例宕机后，新的生产者实例可以保证任何未完成的旧事务要么被提交（Commit），要么被中止（Abort），如此可以使新的生产者实例从一个正常的状态开始工作。

而从消费者的角度分析，事务能保证的语义相对偏弱。出于以下原因，Kafka 并不能保证已提交的事务中的所有消息都能够被消费：

- 对采用日志压缩策略的主题而言，事务中的某些消息有可能被清理（相同key的消息，后写入的消息会覆盖前面写入的消息）。
- 事务中消息可能分布在同一个分区的多个日志分段（LogSegment）中，当老的日志分段被删除时，对应的消息可能会丢失。
- 消费者可以通过seek（）方法访问任意offset的消息，从而可能遗漏事务中的部分消息。
- 消费者在消费时可能没有分配到事务内的所有分区，如此它也就不能读取事务中的所有消息。

## 事物方法

- initTransactions
- beginTransaction
- sendOffsetsToTransaction
- commitTransaction
- abortTransaction
- `sendOffsetsToTransaction`

## isolation.level

在消费端有一个参数isolation.level，与事务有着莫大的关联，这个参数的默认值为“read_uncommitted”，意思是说消费端应用可以看到（消费到）未提交的事务，当然对于已提交的事务也是可见的。这个参数还可以设置为“read_committed”，表示消费端应用不可以看到尚未提交的事务内的消息。举个例子，如果生产者开启事务并向某个分区值发送3条消息msg1、msg2和msg3，在执行commitTransaction（）或abortTransaction（）方法前，设置为“read_committed”的消费端应用是消费不到这些消息的，不过在KafkaConsumer内部会缓存这些消息，直到生产者执行 commitTransaction（）方法之后它才能将这些消息推送给消费端应用。反之，如果生产者执行了 abortTransaction（）方法，那么 KafkaConsumer 会将这些缓存的消息丢弃而不推送给消费端应用。

transaction_status 包 含

- Empty（0）
- Ongoing（1）
- PrepareCommit（2）
- PrepareAbort（3）
- CompleteCommit（4）
- CompleteAbort（5）
- Dead（6）这几种状态


## consume-transform-produce流程

- 1.查找TransactionCoordinator
- 2.获取PID,保存PID
- 3.开启事务
- 4.Consume-Transform-Produce
- 5.提交或者中止事务
    - 1）EndTxnRequest
    - 2）WriteTxnMarkersRequest
    - 3）写入最终的COMPLETE_COMMIT或COMPLETE_ABORT

TransactionCoordinator在收到EndTxnRequest请求后会执行如下操作：

- （1）将PREPARE_COMMIT或PREPARE_ABORT消息写入主题__transaction_state
- （2）通过WriteTxnMarkersRequest请求将COMMIT或ABORT信息写入用户所使用的普通主题和__consumer_offsets
- （3）将COMPLETE_COMMIT或COMPLETE_ABORT信息写入内部主题__transaction_state