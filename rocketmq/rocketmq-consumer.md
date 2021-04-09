# Consumer

## Consumer start

启动过程

```java
DefaultMQPushConsumer#start
    ->DefaultMQPushConsumerImpl#start
        -> this.consumeMessageService.start();
        -> this.mQClientFactory.start();
            -> this.mQClientAPIImpl.start();// 启动 Netty client
            -> this.startScheduledTask();
            -> this.pullMessageService.start();
            -> this.rebalanceService.start();
            -> this.defaultMQProducer.getDefaultMQProducerImpl().start(false);
```

## Message Flow

![messgae flow](images/rocketmq-messgae-flow.png)

## DefaultLitePullConsumer

## DefaultMQPushConsumer

## PullMessageService

## Message Ack
