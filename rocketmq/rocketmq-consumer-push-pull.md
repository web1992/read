# RocketMQ PUSH and PULL

从 `PUSH` and `PULL` 的角度去看 Consumer 的消费实现。

- [RocketMQ PUSH and PULL](#rocketmq-push-and-pull)
  - [ConsumeType](#consumetype)
  - [RebalanceImpl](#rebalanceimpl)
  - [MQConsumerInner](#mqconsumerinner)
    - [DefaultLitePullConsumerImpl 的实现](#defaultlitepullconsumerimpl-的实现)
      - [PullTaskImpl#run](#pulltaskimplrun)
    - [DefaultMQPushConsumerImpl 的实现](#defaultmqpushconsumerimpl-的实现)
    - [~~DefaultMQPullConsumerImpl 的实现~~](#defaultmqpullconsumerimpl-的实现)

## ConsumeType

这里先看下`ConsumeType`，分为两种`PULL`和`PUSH`，因此（习惯性我们称）Consumer消费消息主要有两种模式。

Demo [PULL 模式](https://github.com/apache/rocketmq/blob/master/example/src/main/java/org/apache/rocketmq/example/simple/LitePullConsumerSubscribe.java)，[PUSH 模式](https://github.com/apache/rocketmq/blob/master/example/src/main/java/org/apache/rocketmq/example/quickstart/Consumer.java)。从Demo可以看出`PUll`与`PUSH`在使用方式的区别。

这里进行简单的总结：

PUSH 模式，使用 `registerMessageListener` 注册`MessageListener` 就可以实现消息的消费。
PULL 模式，需要使用`while(true)` + `litePullConsumer.poll()`方式，主动的`拉`消息进行消费。

```java
public enum ConsumeType {

    CONSUME_ACTIVELY("PULL"),

    CONSUME_PASSIVELY("PUSH");

    private String typeCN;

    ConsumeType(String typeCN) {
        this.typeCN = typeCN;
    }

    public String getTypeCN() {
        return typeCN;
    }
}
```

## RebalanceImpl

这里说下 `RebalanceImpl`， 因为`RocketMQ`消息的消费的前提是分配了`MessageQueue`（基于`MessageQueue`进行消息的平均消息）。而`RebalanceImpl`(重平衡的作用就是平均的分配`MessageQueue`)。因此这里有必要说下`RebalanceImpl`。

`RebalanceImpl` 有3种实现。

- `RebalanceLitePullImpl`
- `RebalancePullImpl`
- `RebalancePushImpl`

`RebalanceImpl` 的抽象方法

| 方法                          | 描述                                                                       |
| ----------------------------- | -------------------------------------------------------------------------- |
| messageQueueChanged           | 处理Queue变化(比如Consumer上下线，重平衡触发)                              |
| removeUnnecessaryMessageQueue | 也是在重平衡触发之后，做移除queue的操作                                    |
| consumeType                   | `ConsumeType` 目前有 `PULL` 和 `PUSH`                                      |
| removeDirtyOffset             | 移除对 consumer offset 的管理                                              |
| computePullFromWhere          | 拉取消费开始的位置                                                         |
| dispatchPullRequest           | 转发 `PullRequest` 请求，主要针对 `RebalancePushImpl` 实现。其他是空实现。 |

`RebalanceImpl`的三个实现类，是一个`适配类`（主要实现委托给了`*ConsumerImpl`）。主要的实现分别在成员变量`DefaultLitePullConsumerImpl`，`DefaultMQPullConsumerImpl`，`DefaultMQPushConsumerImpl`中。而这个三个类都实现了 `MQConsumerInner`接口。因此下面我们看`MQConsumerInner`。

## MQConsumerInner

`MQConsumerInner` 接口的三个实现类：

- `DefaultLitePullConsumerImpl`
- ~~`DefaultMQPullConsumerImpl`~~
- `DefaultMQPushConsumerImpl`

### DefaultLitePullConsumerImpl 的实现

1. 使用 `while(true)` + `litePullConsumer.poll()`的方式，从`consumeRequestCache`拉取消息
2. 底层使用 `PullTaskImpl` 把查找到的消息`put`进 `consumeRequestCache` 中
3. `PullTaskImpl` 是以`MessageQueue`的维度进行消息拉取的
4. `MessageQueue` 通过 `MessageQueueListener` 回调监听实现queue的更新
5. `messageQueueChanged` 方法是在重平衡之后，触发的事件

MessageQueue 到  PullTaskImpl 的转化

```java
private void updatePullTask(String topic, Set<MessageQueue> mqNewSet) {
    Iterator<Map.Entry<MessageQueue, PullTaskImpl>> it = this.taskTable.entrySet().iterator();
    while (it.hasNext()) {
        Map.Entry<MessageQueue, PullTaskImpl> next = it.next();
        if (next.getKey().getTopic().equals(topic)) {
            if (!mqNewSet.contains(next.getKey())) {
                next.getValue().setCancelled(true);
                it.remove();
            }
        }
    }
    startPullTask(mqNewSet);
}
private void startPullTask(Collection<MessageQueue> mqSet) {
    for (MessageQueue messageQueue : mqSet) {
        if (!this.taskTable.containsKey(messageQueue)) {
            PullTaskImpl pullTask = new PullTaskImpl(messageQueue);
            this.taskTable.put(messageQueue, pullTask);
            this.scheduledThreadPoolExecutor.schedule(pullTask, 0, TimeUnit.MILLISECONDS);
        }
    }
}
```

#### PullTaskImpl#run

[PullTaskImpl#run](https://github.com/apache/rocketmq/blob/master/client/src/main/java/org/apache/rocketmq/client/impl/consumer/DefaultLitePullConsumerImpl.java#L686) 方法是PULL模式下消息拉取的核心实现，下面进行简单介绍。

1. 检查 MessageQueue 是否已经暂定，（因为重平衡之后MessageQueue就重新分配了，MessageQueue 可能分配给其他Consumer了。当前的就需要暂停）
2. 检查 ProcessQueue 是否暂停
3. 检查 consumeRequestCache 中缓存的消息是否超过最大限制。避免Consumer客户端的内存不足。
4. 通过 processQueue 检查 cachedMessageCount 和 cachedMessageSizeInMiB 是否超过最大值
5. 通过 processQueue 检查 maxSpan
6. 包装 PullResult 执行 pull 方法
7. 如果找到 Msg ，把 msg 包装成 ConsumeRequest 进行异步消费
8. 更新 updatePullOffset

### DefaultMQPushConsumerImpl 的实现

此处以 MessageListenerConcurrently 并发消息为例。

1. 使用 `registerMessageListener` 注册`MessageListenerConcurrently`进行消息的消费
2. ConsumeMessageConcurrentlyService 内存维护了 ConsumeRequest， ConsumeRequest 触发 MessageListener 的 consumeMessage 方法进行消费。
3. ConsumeRequest 实现了Runnable，可以提交给线程池做异步处理。
4. ConsumeRequest 来自 ConsumeMessageConcurrentlyService#submitConsumeRequest 方法，此方法包含了需要消费的消息 `List<MessageExt>`
5. PullCallback 中调用 ConsumeMessageConcurrentlyService#submitConsumeRequest 提交`List<MessageExt>`
6. PullMessageService 线程中维护了 PullRequest 队列，会定期的执行take+pullMessage 拉取消息 包装
7. PullRequest 是通过 RebalanceImpl#updateProcessQueueTableInRebalance 方法 MessageQueue 包装来的。并把 PullRequest 放入到 PullMessageService 中
8. MessageQueue 也是通过重平衡而来的

`MessageQueue` 到 `PullRequest` 的转化（代码片段：）

```java
for (MessageQueue mq : mqSet) {
 // 省略其他代码
 PullRequest pullRequest = new PullRequest();
 pullRequest.setConsumerGroup(consumerGroup);
 pullRequest.setNextOffset(nextOffset);
 pullRequest.setMessageQueue(mq);
 pullRequest.setProcessQueue(pq);
 pullRequestList.add(pullRequest);
}
// add PullRequest
this.dispatchPullRequest(pullRequestList);
```

拉取消息的核心方法是[源码地址 DefaultMQPushConsumerImpl#pullMessage](https://github.com/apache/rocketmq/blob/master/client/src/main/java/org/apache/rocketmq/client/impl/consumer/DefaultMQPushConsumerImpl.java#L213)。可以参考 [pullMessage 的流程步骤](rocketmq-consumer.md#consumer-拉取消息的流程)

### ~~DefaultMQPullConsumerImpl 的实现~~

~~`DefaultMQPullConsumerImpl` 此实现已经过期，不建议使用。~~ 废弃原因是暴露了底层的API，太过于复杂。使用不友好。可以看下下面的使用例子。

[DefaultMQPullConsumerImpl 的使用Demo](https://github.com/apache/rocketmq/blob/master/example/src/main/java/org/apache/rocketmq/example/simple/PullConsumer.java)

因此如果使用 PULL 模式推荐使用 DefaultLitePullConsumerImpl 。DefaultLitePullConsumerImpl 进行了封装，进行了 `flow control`。
