# RocketMQ FAQ

`RocketMQ` 100 问。`RocketMQ` 的常见问题，下面的问题之间互为`"因果"`，有些问题已经可以回答某项问题。

列举下面的问题主要目的是 `带着问题看RocketMQ`，事半功倍。

- `RocketMQ` 为什么不建议在生产环境中使用自动创建Topic这个功能
- `RocketMQ` 路由信息是什么，为什么需要它
- `RocketMQ` 中的`queueId`的作用
- `RocketMQ` 中 tags 是作用是什么
- `RocketMQ` 的负载均衡的实现，`Borker`的负载均衡和`Consumer`的负载均衡的实现
- `RocketMQ` HA 的实现
- `RocketMQ` 的主从（master/slave）实现
- `RocketMQ` 存储的如何实现高性能的
- `RocketMQ` 中的一条Msg消息是如何存在在文件中的（以什么样的格式）
- `RocketMQ` 顺序消费消息的实现
- `RocketMQ` 事物消息的实现
- `RocketMQ` 消息消费失败的处理方式
- `RocketMQ` 的序列化
- `RocketMQ` 如何记录消息消费的位置(offset)，在重启之后继续消费
- `RocketMQ` 如何通过`MessageId`查询一个消息
- `RocketMQ` Client(Producer&Consumer) 与 Borker 的通信方式
- `RocketMQ` consumerQueue 的作用
- `RocketMQ` rebalance 的作用
- `RocketMQ` 在消息消费失败之后，把消息发送到 Broker 之后，是如何存储的，MessageId 会变吗，存储的位置会变吗
- `RocketMQ` 中事物消息 `RMQ_SYS_TRANS_HALF_TOPIC` 在事物失败之后，会被从磁盘删除吗，还是只是标记了删除
- `RocketMQ` 事物消息的回查是如何触发的（查询事物消息的状态）
- `RocketMQ` Consumer 是如何知道有消息可以消费了，是 Consumer Pull 还是 Borker Push
- `RocketMQ` Consumer 消费过慢会怎么样
- `RocketMQ` 批量消息的使用场景
- `RocketMQ` 与 kafka 的对比，场景用kafka，什么场景用 RocketMQ。以及各自的优缺点。
- `RocketMQ` 消费失败的次数超过最大次数（默认是16次）会对消息做什么特殊的处理

## Links

- [https://www.confluent.io/blog/how-choose-number-topics-partitions-kafka-cluster/](https://www.confluent.io/blog/how-choose-number-topics-partitions-kafka-cluster/)
- [RocketMQ 常见问题](https://mp.weixin.qq.com/s/mNpXpSVVVBuI59LI6vVvQA)
- [Exactly once](https://cloud.tencent.com/developer/article/1768876)