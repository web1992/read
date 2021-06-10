# RocketMQ Consumer Orderly

RocketMQ 的顺序消费和并发消费的实现细节。

客户端使用 `MessageListenerConcurrently` 和 `MessageListenerOrderly` 来确定顺序消费还是并行消费。
而具体的实现类是：`ConsumeMessageOrderlyService` 和 `ConsumeMessageConcurrentlyService`

## 初始化

在消息消费初始中可以使用 `MessageListenerOrderly` 进行消息的顺序消费，使用 `MessageListenerConcurrently` 进行消息的并发消费。

```java
// consumer 在启动之前需要先确定使用 MessageListenerConcurrently 还是 MessageListenerOrderly
consumer.registerMessageListener(new MessageListenerConcurrently() {
    @Override
    public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs,
        ConsumeConcurrentlyContext context) {
        System.out.printf("%s Receive New Messages: %s %n", Thread.currentThread().getName(), msgs);
        return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
    }
});
```

在后续的启动过程中根据 `MessageListenerConcurrently` 还是 `MessageListenerOrderly` 来启动 `ConsumeMessageOrderlyService` 还是 `ConsumeMessageConcurrentlyService`
代码如下：

```java
if (this.getMessageListenerInner() instanceof MessageListenerOrderly) {
    this.consumeOrderly = true;
    // 使用 ConsumeMessageOrderlyService
    this.consumeMessageService =
        new ConsumeMessageOrderlyService(this, (MessageListenerOrderly) this.getMessageListenerInner());
} else if (this.getMessageListenerInner() instanceof MessageListenerConcurrently) {
    this.consumeOrderly = false;
    // 使用 ConsumeMessageConcurrentlyService
    this.consumeMessageService =
        new ConsumeMessageConcurrentlyService(this, (MessageListenerConcurrently) this.getMessageListenerInner());
}
// 启动 ConsumeMessageService
this.consumeMessageService.start();
```

## ConsumeMessageService 的两种实现

`ConsumeMessageOrderlyService` 和 `ConsumeMessageConcurrentlyService` 都实现了 `ConsumeMessageService` 接口。

接口的方法：

```java
// org.apache.rocketmq.client.impl.consumer.ConsumeMessageService
public interface ConsumeMessageService {
void start();
void shutdown(long awaitTerminateMillis);
void updateCorePoolSize(int corePoolSize);
void incCorePoolSize();
void decCorePoolSize();
int getCorePoolSize();
ConsumeMessageDirectlyResult consumeMessageDirectly(final MessageExt msg, final String brokerName);
void submitConsumeRequest(
    final List<MessageExt> msgs,
    final ProcessQueue processQueue,
    final MessageQueue messageQueue,
    final boolean dispathToConsume);
}

```

核心方法是 `start`，`consumeMessageDirectly`和`submitConsumeRequest`，下面做对比：

| 方法                   | ConsumeMessageOrderlyService                                                        | ConsumeMessageConcurrentlyService                                                                                                    |
| ---------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| start                  | 启动了 `ConsumeMessageOrderlyService.this.lockMQPeriodically()` 定时任务            | 启动了一个 `cleanExpireMsg` 定时任务                                                                                                 |
| consumeMessageDirectly | 处理 ConsumeOrderlyStatus 返回 ConsumeMessageDirectlyResult                         | 这里的实现比较简单，就是消费消息 处理 ConsumeConcurrentlyStatus，返回 ConsumeMessageDirectlyResult                                   |
| submitConsumeRequest   | 把`List<MessageExt>`包装成 `ConsumeRequest` 提交给 `consumeExecutor` 线程池异步消息（consumeExecutor线程池不是单线程池） | 把`List<MessageExt>`包装成 `ConsumeRequest` 提交给 `consumeExecutor` 线程池异步消息，因为`consumeExecutor`多个线程的，因此是并发消费 |

从上面的对比中看，似乎没有说明 `ConsumeMessageOrderlyService` 与 `ConsumeMessageConcurrentlyService` 的区别在哪里。然而他们的 `ConsumeRequest` 是不同的，`ConsumeRequest` 是二个类的内部类。具体的不同实现就在 `ConsumeRequest` 中

- `org.apache.rocketmq.client.impl.consumer.ConsumeMessageOrderlyService.ConsumeRequest`
- `org.apache.rocketmq.client.impl.consumer.ConsumeMessageConcurrentlyService.ConsumeRequest`

> 此处不再解释 `submitConsumeRequest` 方法参数 `List<MessageExt> msgs`,`ProcessQueue` 等的来源。具体可以在 [消息消费的实现](rocketmq-consumer.md) 中查看。

## ConsumeMessageOrderlyService.ConsumeRequest

代码流程：

- 加锁
- 做检查
- 执行 `this.processQueue.takeMessages(consumeBatchSize);` 这里是核心，因为 consumeBatchSize =1，所以每次只取一条消息
- 构造 ConsumeOrderlyContext
- 执行 executeHookBefore
- 执行 `this.processQueue.getLockConsume().lock();` 再次加锁
- 执行 messageListener.consumeMessage 消费消息
- 处理 ConsumeOrderlyStatus 结果
- 执行 executeHookAfter
- 执行 getConsumerStatsManager 进行统计
- 执行 `processConsumeResult` 这里处理顺序消费的结果，如果消费失败会把消息重新放回到中 ConsumeRequest 中，等待下一次消费。

这里说下加锁的实现：

```java
// messageQueueLock 为每个 MessageQueue 分配一个Lock Object
// 这样多个线程在进行处理 ConsumeRequest 中的run 方法的时候，都会尝试获取锁。
// 那么每个 MessageQueue 的消息顺序只会有一个线程，这样就包装了在 同一个 MessageQueue 消息消费是顺序进行的。
final Object objLock = messageQueueLock.fetchLockObject(this.messageQueue);
synchronized (objLock) {
     // 消费消息的代码
 }
```

看上面的代码，应该有这个的疑问，`ConsumeMessageOrderlyService` 消息，只是保证了单个`queueId`下面的顺序消费，而在`queue`是多个，那么在`RocketMQ`如果保证全局的顺序性呢？
这个就需要`Producer`+`Consumer`端保证了。具体的Demo例子可以参考 [Producer+Consumer orderly](https://github.com/apache/rocketmq/blob/master/example/src/main/java/org/apache/rocketmq/example/ordermessage)

## ConsumeMessageConcurrentlyService.ConsumeRequest

代码流程：

- 构造 ConsumeConcurrentlyContext 上下文
- 执行 `executeHookBefore` Hooks
- 执行 `listener.consumeMessage` 也就是和业务相关的代码
- 处理 ConsumeConcurrentlyStatus 返回结果
- 执行 `ConsumeConcurrentlyStatus` Hooks
- 通过 getConsumerStatsManager 更新统计信息
- 执行 processConsumeResult 处理消费结果

## 再谈重平衡

`RebalanceImpl` 重平衡中，包含了针对顺序消费的特殊处理。因此这里在进行说明。如果没有顺序消费的逻辑。重平衡的逻辑对简单很多。
这里从 [RebalanceImpl#updateProcessQueueTableInRebalance](https://github.com/apache/rocketmq/blob/master/client/src/main/java/org/apache/rocketmq/client/impl/consumer/RebalanceImpl.java#L328)开始看细节。

首先代码从`Iterator<Entry<MessageQueue, ProcessQueue>> it = this.processQueueTable.entrySet().iterator();` 中获取 `iterator` 进行遍历
删除那些已经`dropped`和过期的`MessageQueue`，此外，如果是顺序消费。还会是使用`this.lock(mq)`进行加锁。如果加锁成功。才会分配此MessageQueue。具体代码结果如下：

```java
// mqSet 是在执行 AllocateMessageQueueStrategy#allocate 之后分配到的 MessageQueue List
Set<MessageQueue> mqSet =...
// 过滤，删除 在 processQueueTable 无效的 MessageQueue
for (MessageQueue mq : mqSet) {
    if (!this.processQueueTable.containsKey(mq)) {// 这里不包含才执行，如果存在，说明MessageQueue之前已经分配给此Consumer了
        // ...
        if (isOrder && !this.lock(mq)) {
        // 加锁失败。不使用此 MessageQueue
        continue;
        }     
        // 没有则放入
        // 把 MessageQueue 放入到 processQueueTable 中
        ProcessQueue pre = this.processQueueTable.putIfAbsent(mq, pq);

        // ... 构造PullRequest 放入线程池，拉取消息消费
        PullRequest pullRequest = new PullRequest();
        pullRequest.setConsumerGroup(consumerGroup);
        pullRequest.setNextOffset(nextOffset);
        pullRequest.setMessageQueue(mq);
        pullRequest.setProcessQueue(pq);
        pullRequestList.add(pullRequest);

    }
}

```

这里说下 `this.lock(mq)`加锁的过程，其实就是发送 `LockBatchRequestBody` 请求去主(Master)Borker申请锁。

- LockBatchRequestBody 加锁
- UnlockBatchRequestBody 解锁

加锁的实现就是循环处理 `MessageQueue` ，从`ConcurrentHashMap`拿到以`mq`为`key`取`LockEntry`，如果为空包装 `LockEntry` 放入到中`ConcurrentHashMap`，放入之后对比`clientId`是否相等，相等就认为是加锁成功。
代码结果如下（省略非核心部分）：

```java
// 加锁成功的Set
Set<MessageQueue> lockedMqs = ...

// get ConcurrentHashMap by consumer group
ConcurrentHashMap<MessageQueue, LockEntry> groupValue = this.mqLockTable.get(group);

for (MessageQueue mq : notLockedMqs) {
// put
lockEntry = new LockEntry();
lockEntry.setClientId(clientId);
groupValue.put(mq, lockEntry);

// check
if (lockEntry.isLocked(clientId)) {
     lockEntry.setLastUpdateTimestamp(System.currentTimeMillis());
     lockedMqs.add(mq);
     continue;
 }
}
// 返回加锁成功的
return lockedMqs
```

此外，上面的代码省略了`续锁`(如果之前已经获取了锁，就延迟锁的过期时间)的操作。

## Links

- [RocketMQ 顺序消费](https://www.cnblogs.com/qdhxhz/p/11134903.html)
