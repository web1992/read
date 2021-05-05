# Producer

## Msg 的发送

`Message` -> `CommandCustomHeader` -> `RemotingCommand` -> `byte[]` -> TPC -> `Broker` -> `SendResult`

## SendResult

## DefaultMQProducer

```java
public class DefaultMQProducer extends ClientConfig implements MQProducer {
// ...
}
```

## MessageQueue

`queueId` 的获取

```java
// 选择 MessageQueue  DefaultMQProducerImpl#selectOneMessageQueue
MessageQueue mqSelected = this.selectOneMessageQueue(topicPublishInfo, lastBrokerName);
mq = mqSelected;

// 发消息 DefaultMQProducerImpl#sendDefaultImpl
sendResult = this.sendKernelImpl(msg, mq, communicationMode, sendCallback, topicPublishInfo, timeout - costTime);

// ... DefaultMQProducerImpl#sendKernelImpl
SendMessageRequestHeader requestHeader = new SendMessageRequestHeader();
// get QueueId
requestHeader.setQueueId(mq.getQueueId());
```
