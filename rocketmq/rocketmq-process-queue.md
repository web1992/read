# ProcessQueue

ProcessQueue 维护的信息比较多，看起来比较复杂，但是他的作用也很简单，ProcessQueue 的作用：

- 维护 MessageExt 维护拉取到的Msg
- 维护锁 包装顺序消费
- 维护 msgCount 和 msgSize 避免内存溢出问题

可以理解为 ProcessQueue 是 comsumer 端了为了控制拉取消息进度维护了一些统计信息。避免频繁的拉取消息导致 consumer 内存溢出等问题。

如果 comsumer 处理消息比较耗时（慢），你拉取过多的消息到本地缺消费玩，没有意义，因此需要控制频率。

- [ProcessQueue 源码](https://github.com/apache/rocketmq/blob/develop/client/src/main/java/org/apache/rocketmq/client/impl/consumer/ProcessQueue.java#L41)