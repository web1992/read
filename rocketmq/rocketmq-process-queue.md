# ProcessQueue

ProcessQueue 的作用：

- 维护 MessageExt 维护拉取到的Msg
- 维护锁 包装顺序消费
- 维护 msgCount 和 msgSize 避免内存溢出问题