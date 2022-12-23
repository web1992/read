# ConsumerSendMsgBackRequestHeader

> 消息消费失败的处理逻辑

- 针对顺序消费的，消息消费失败的处理：会把消息从新放到 `ProcessQueue#msgTreeMap` 中（不更新offset）,一直到消费成功才会真正的从 msgTreeMap 中移除，并更新 offset

针对`非顺序`消息消费失败的处理逻辑，具体代码逻辑在 [SendMessageProcessor#asyncConsumerSendMsgBack](https://github.com/apache/rocketmq/blob/master/broker/src/main/java/org/apache/rocketmq/broker/processor/SendMessageProcessor.java#L112) 方法中。

这里简单进行流程梳理（`非顺序`消息消费失败的处理逻辑）：

1. 执行 executeConsumeMessageHookAfter hooks
2. 检查订阅信息
3. 检查写权限
4. 检查 reteryQueue
5. 根据 ConsumerGriup 创建新的 newTopic
6. 获取路由信息
7. 检查写权限
8. 查询消息 MessageExt
9. 检查是否超过最大的重试次数 maxReconsumeTimes 如果是，则返回失败
10. 更新消息的 DELAY 属性
11. 组装消息并存储
