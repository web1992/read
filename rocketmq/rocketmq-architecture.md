# RocketMQ Architecture

RocketMQ 架构和相关的概念

| 名词               | 描述                                                                 |
| ------------------ | -------------------------------------------------------------------- |
| NameServer Cluster | `服务注册`中心集群，负责 Borker注册和发现                            |
| Broker Cluster     | `Broker`集群,`RocketMQ`的大脑，负责消息的存储和查询等等,支持主从配置 |
| Producer Cluster   | 生产者集群，负责发消息                                               |
| Consumer Cluster   | 消费者集群，负责消费消息                                             |

## Links

- [https://rocketmq.apache.org/docs/rmq-arc/](https://rocketmq.apache.org/docs/rmq-arc/)