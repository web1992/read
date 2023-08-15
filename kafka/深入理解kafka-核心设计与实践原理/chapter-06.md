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
- 定时器（SystemTimer）
- 

## 时间轮

JDK中Timer和DelayQueue的插入和删除操作的平均时间复杂度为O（nlogn）并不能满足Kafka的高性能要求，而基于时间轮可以将插入和删除操作的时间复杂度都降为O（1）。时间轮的应用并非Kafka独有，其应用场景还有很多，在Netty、Akka、Quartz、ZooKeeper等组件中都存在时间轮的踪影。

