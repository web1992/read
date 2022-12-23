# High Availability

RocketMQ 的高可用的实现。

RocketMQ 构架图：

![rmq-basic-arc.png](./images/rmq-basic-arc.png)

从构架图中可知道，RocketMQ 支持多个 NameServer,多个 Master Broker 和 多个 Slave Broker 的。

## Links

- [主从同步注意点](https://cloud.tencent.com/developer/article/1458089)
- [RocketMQ HA机制](https://developer.aliyun.com/article/839243)