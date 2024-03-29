# Consumer

RocketMQ 消费消息的实现解析。

目录：

- [Consumer](#consumer)
  - [消息的创建和消费](#消息的创建和消费)
  - [消息消费的核心类](#消息消费的核心类)
  - [Consumer 的启动](#consumer-的启动)
    - [DefaultMQPushConsumerImpl#start](#defaultmqpushconsumerimplstart)
    - [MQClientInstance#start](#mqclientinstancestart)
  - [Consumer 拉取消息的流程](#consumer-拉取消息的流程)
    - [PullMessageService](#pullmessageservice)
    - [PullRequest](#pullrequest)
    - [PullResult](#pullresult)
  - [Consumer 消费结果的处理](#consumer-消费结果的处理)
    - [ConsumeRequest](#consumerequest)
    - [processConsumeResult](#processconsumeresult)
    - [sendMessageBack](#sendmessageback)
    - [ProcessQueue](#processqueue)
  - [RebalancePushImpl#computePullFromWhere](#rebalancepushimplcomputepullfromwhere)
  - [Consumer 的负载均衡](#consumer-的负载均衡)
    - [RebalanceImpl Consumer的重平衡](#rebalanceimpl-consumer的重平衡)
    - [MessageQueue 的分配策略](#messagequeue-的分配策略)
  - [Links](#links)

可以了解的内容：

- Consumer 消费消息的流程
- Consumer 消费消息失败了，怎么处理
- Consumer 在重启之后，如何继续上一次消费的位置，继续处理
- Consumer 为什么需要重平衡(rebalance)
- RocketMQ 为什么没有办法保证消息的不重复消费。
- 消息消费失败最大次数的控制是如何实现的
- Consumer 的Queue的分配策略

## 消息的创建和消费

此文主要是解释Consumer：消息消费的整体流程，拉取消息，消费消息，消费结果处理，Consumer 的重平衡。可以了解 Consumer 实现类的各个角色。从而为深入了解各个角色的源码做准备。

![messgae flow](images/rocketmq-consumer-create-consumer.svg)

## 消息消费的核心类

三种消息消费的实现类：

- DefaultLitePullConsumer
- ~~DefaultMQPullConsumer~~
- DefaultMQPushConsumer

RockerMQ 中的（Client）Consumer 实现也是比较复杂的，主要是涉及的类很多，而且各个类之间都相互关联。
虽然 Consumer 的主要作用是消费消息，但是很多功能都是在 Consumer 端实现的。比如：
- 1.(Pull 模式)拉取消息进行消费。
- 2.消息消费失败，重新发回到MQ。
- 3.多个 Consumer 消费者之间的`负载均衡`。
- 4.持久化消费者的 offset(消费进度位置) 等等。

`offset` 的解释：如果现在有100条消息，我消费了50条，那么offset=50,下次可从offset51拉消息，进行消费。

而下图中的类，就是负责上述的这些功能（类真的多！）。

![rocketmq-consumer-class](images/rocketmq-consumer.svg)

如果我们不关心消费端的实现，只使用消费消息的功能。我们使用 `DefaultMQPushConsumer` 和 `MessageListenerConcurrently`(`MessageListener`) 就可以完成消息的消费了。
但是如果我们要关心实现，那么上图中的类，都需要了解，下面对主要的类进行简单的说明：

- `DefaultMQPushConsumer` （Consumer 入口）负责 Consumer 的启动&管理配置参数
- `DefaultMQPushConsumerImpl` 负责发送 `PullRequest` 拉消息,包含 `ConsumeMessageService` 和 `MQClientInstance`
- `ConsumeMessageService` 负责处理消息服务(有 `ConsumeMessageConcurrentlyService` 和 `ConsumeMessageOrderlyService` )两种实现
- `MQClientInstance`(mQClientFactory) 负责底层的通信(单实例的，多个Consumer会共享一个)
- `RebalanceImpl` 执行 rebalance (重平衡)

## Consumer 的启动

消息消费者(client)的启动过程(这里列举了启动的核心类)：

```java
DefaultMQPushConsumer#start
    ->DefaultMQPushConsumerImpl#start
        -> this.consumeMessageService.start();
        -> this.mQClientFactory.start();// MQClientInstance
            -> this.mQClientAPIImpl.start();// MQClientInstance 启动 Netty client
            -> this.startScheduledTask();// MQClientInstance 定时任务
            -> this.pullMessageService.start();// PullMessageService 
            -> this.rebalanceService.start();// RebalanceService
            -> this.defaultMQProducer.getDefaultMQProducerImpl().start(false);
```

![启动图](./images/rocketmq-consumer-start.svg)

下面是各个启动类的代码片段：

### DefaultMQPushConsumerImpl#start

`DefaultMQPushConsumerImpl` 的主要功能是拉取消息进行消费，下面 从 `start` 和 `pullMessage` 方法中去了解消息消费的核心。

消息消费的启动过程如下：

```java
// DefaultMQPushConsumerImpl#start
// 1. 检查配置
// 2. copy copySubscription
// 3. 创建 mQClientFactory
// 4. 创建 pullAPIWrapper
// 5. 注册 filterMessageHookList
// 6. 获取 offsetStore 并且加载 offset
// 7. 创建 consumeMessageService 并且启动，有序的 ConsumeMessageOrderlyService , 无序的的 ConsumeMessageConcurrentlyService
// 8. 注册 Consumer mQClientFactory.registerConsumer
// 9. 启动 mQClientFactory
// 10. 更新 topic 的订阅信息
// 11. 校验 checkClientInBroker
// 12. 发送心跳到 broker
// 13. rebalanceImmediately 执行 rebalance 操作
public synchronized void start() throws MQClientException {
// ...
this.updateTopicSubscribeInfoWhenSubscriptionChanged();// 10
this.mQClientFactory.checkClientInBroker();// 11
this.mQClientFactory.sendHeartbeatToAllBrokerWithLock();// 12
this.mQClientFactory.rebalanceImmediately();// 13
}
```

### MQClientInstance#start

```java
// MQClientInstance 的启动
public void start() throws MQClientException {
    synchronized (this) {
        switch (this.serviceState) {
            case CREATE_JUST:
                this.serviceState = ServiceState.START_FAILED;
                // If not specified,looking address from name server
                if (null == this.clientConfig.getNamesrvAddr()) {
                    this.mQClientAPIImpl.fetchNameServerAddr();
                }
                // Start request-response channel
                this.mQClientAPIImpl.start();
                // Start various schedule tasks
                this.startScheduledTask();
                // Start pull service
                this.pullMessageService.start();
                // Start rebalance service
                this.rebalanceService.start();
                // Start push service
                this.defaultMQProducer.getDefaultMQProducerImpl().start(false);
                log.info("the client factory [{}] start OK", this.clientId);
                this.serviceState = ServiceState.RUNNING;
                break;
            case START_FAILED:
                throw new MQClientException("The Factory object[" + this.getClientId() + "] has been created before, and failed.", null);
            default:
                break;
        }
    }
}
```

## Consumer 拉取消息的流程

消费者从 Broker 拉取消息，进行消费的主要实现是在 `DefaultMQPushConsumerImpl#pullMessage` 方法中。
这里我们先看下整理的流程（细节太多，不一一看了。）

1. 拉取消息的准备阶段和执行阶段。获取消息的过程如下：

```java
// DefaultMQPushConsumerImpl#pullMessage
// pullMessage 方法的声明,注意返回值是 void，参数是 PullRequest

// 1. 检查 ProcessQueue
// 2. 更新 ProcessQueue 的 lastPullTimestamp
// 3. 检查 serviceState 状态
// 4. 检查 DefaultMQPushConsumerImpl 的 pause 标记
// 5. 检查 cachedMessageCount （在 ProcessQueue 中），如果超过，则延迟 PullRequest
// 6. 检查 cachedMessageSizeInMiB 的大小。超过多少100M，则延迟 PullRequest
// 7. 如果是按照顺序消费&检查 getMaxSpan 是否超过 2000，超过则延迟 PullRequest
// 8. 检查 processQueue 的锁状态
// 9. 检查是否是一次 pull Msg,计算 offset 从哪里开始消费，并更新 offset
// 10. 获取 SubscriptionData  
// 11. 包装 PullCallback
// 12. 获取  commitOffsetValue
// 13. 获取  SubscriptisonData
// 14. build  sysFlag
// 15. 执行 pullKernelImpl (本质是发送 PullMessageRequestHeader 去拉消息)
//  ↓
//  TCP
//  ↓
// 这里说明下，把 PullMessageRequestHeader broker 之后，等待异步响应，
// 获取  PullMessageResponseHeader 响应之后，执行回调 PullCallback
public void pullMessage(final PullRequest pullRequest) {
// ...   
}
```

要理解底层的一些细节，必须了解的二个类：

- [ProcessQueue](rocketmq-process-queue.md)
- [MessageQueue](rocketmq-message-queue.md)

消息消费的简化图：

![rocketmq-consumer-consumer-simple.svg](images/rocketmq-consumer-consumer-simple.svg)

### PullMessageService

`PullMessageService` 是一个线程，这里我称它为 `拉取消息的线程`。后面会再次提到它。

```java
// PullMessageService 的定义，本质是一个线程
public class PullMessageService extends ServiceThread {
// ...    
}
// 线程的 Run 方法
public void run() {
   // ...
    this.pullMessage(pullRequest);
   //...
}

// 拉取消息
private void pullMessage(final PullRequest pullRequest) {
    final MQConsumerInner consumer = this.mQClientFactory.selectConsumer(pullRequest.getConsumerGroup());
    if (consumer != null) {
        DefaultMQPushConsumerImpl impl = (DefaultMQPushConsumerImpl) consumer;
        impl.pullMessage(pullRequest);
    } else {
        log.warn("No matched consumer for the PullRequest {}, drop it", pullRequest);
    }
}
```

上面的 `pullMessage` 方法最终会调用 `DefaultMQPushConsumerImpl#pullMessage` 方法

### PullRequest

2.执行拉取消息的阶段

`org.apache.rocketmq.client.impl.consumer.PullRequest` 是一个拉取消息的`请求`类。首先 PullRequest 会在 `RebalanceImpl` 中创建，然后加入到 PullMessageService 线程的 queue 中。
`PullMessageService` 线程会对 queue 执行 take 操作，执行拉取操作。无论是否拉取到新消息，在进行拉取消息之后， 然后再把 PullRequest 放入到 queue 中,以此循环。

```java
// RebalanceImpl 中 PullRequest 的创建
PullRequest pullRequest = new PullRequest();
pullRequest.setConsumerGroup(consumerGroup);
pullRequest.setNextOffset(nextOffset);
pullRequest.setMessageQueue(mq);
pullRequest.setProcessQueue(pq);
pullRequestList.add(pullRequest);
```

在 PullCallback 中会执行拉消息的回调处理，在这里会更新 `nextOffset`,代码片段如下：

```java
long prevRequestOffset = pullRequest.getNextOffset();
// 使用 pullResult 更新 nextOffset
pullRequest.setNextOffset(pullResult.getNextBeginOffset());
```

### PullResult

`org.apache.rocketmq.client.consumer.PullResult` 是拉取消息的结果

```java
// PullCallback 在中的 PullResult
PullCallback pullCallback = new PullCallback() {
    @Override
    public void onSuccess(PullResult pullResult) {
        // 处理 PullResult
    }
}

// PullResult 的字段
public class PullResult {
    private final PullStatus pullStatus;
    private final long nextBeginOffset;
    private final long minOffset;
    private final long maxOffset;
    private List<MessageExt> msgFoundList;// 拉取到的消息列表
}
```

## Consumer 消费结果的处理

### ConsumeRequest

3.在获取到`PullResult`之后（此时已经有了`List<MessageExt>`），进入到消费消息的阶段。

```java
// 在获取到 PullResult 之后，执行 ConsumeMessageService 的 submitConsumeRequest 方法
DefaultMQPushConsumerImpl.this.consumeMessageService.submitConsumeRequest(
                                    pullResult.getMsgFoundList(),// pullResult 中的消息
                                    processQueue,
                                    pullRequest.getMessageQueue(),
                                    dispatchToConsume);
// submitConsumeRequest 方法
public void submitConsumeRequest(
    final List<MessageExt> msgs,
    final ProcessQueue processQueue,
    final MessageQueue messageQueue,
    final boolean dispatchToConsume) {
    // ...
    // 包装成 ConsumeRequest
    ConsumeRequest consumeRequest = new ConsumeRequest(msgs, processQueue, messageQueue);
    // ...
    // 提交给线程池，进行异步的消费处理
    this.consumeExecutor.submit(consumeRequest);
}
```

从上可知整体流程：在拉取到消息之后，获取到 `PullResult` ，然后包装成 `ConsumeRequest` 提交给线程池，进行消息的消费。
这里说下为什么需要使用新的线程池去消息消息。使用新的线程池，主要是处理 `ConsumeRequest` 任务。这些任务会与业务逻辑的代码在一个线程执行。
而业务逻辑的耗时是不可控的，如果执行的时间过长，那么就导致线程池的耗尽。而使用新的线程池，可以与 `拉取消息的线程池`(`PullMessageService`) 分开(隔离)。这样避免上述问题的发生。

此外也引出的另一个问题，如果消息消费过慢，那么`拉取消息的线程` 会进入怎么样的状态呢？(RocketMQ 根据内存占用，等统计信息对拉取信息进行了限流)

`ConsumeRequest` 消息消费的代码片段。

```java
// org.apache.rocketmq.client.impl.consumer.ConsumeMessageConcurrentlyService.ConsumeRequest
// org.apache.rocketmq.client.impl.consumer.ConsumeMessageOrderlyService.ConsumeRequest
class ConsumeRequest implements Runnable {
// ConsumeRequest 实现了 Runnable 可以提交给线程池
}

// 以 ConsumeMessageConcurrentlyService 中的 ConsumeRequest 为例子
// ConsumeRequest 的创建
// 三个参数：
// List<MessageExt> msgs
// ProcessQueue processQueue
// MessageQueue messageQueue
ConsumeRequest consumeRequest = new ConsumeRequest(msgs, processQueue, messageQueue);

// run 方法
@Override
public void run() {
    // ... 这里是我熟悉的 listener 的 consumeMessage 的方法
    MessageListenerConcurrently listener = //...
    // ... 消费消息
    status = listener.consumeMessage(Collections.unmodifiableList(msgs), context); 
}
```

### processConsumeResult

这里以 `ConsumeMessageConcurrentlyService#processConsumeResult` 实现为例子。

在我们了解如何从 Borker 拉取消息之后，再来看看，消息消费的结果是如何处理的。具体的代码逻辑在 `ConsumeMessageConcurrentlyService#processConsumeResult` 方法中。

> 处理消费结果，这里能找到消息消费失败之后的处理，把消息再次`发回`到 Broker。

`processConsumeResult` 中的核心内容是： 消息消费结果的处理&更新offset(消息消费的位置offset)。

```java
//  ConsumeMessageConcurrentlyService 的代码片段
public void processConsumeResult(
    final ConsumeConcurrentlyStatus status,
    final ConsumeConcurrentlyContext context,
    final ConsumeRequest consumeRequest
) {
// 省略了其他代码...
int ackIndex = consumeRequest.getMsgs().size() - 1;
 switch (status) {
     case CONSUME_SUCCESS:// 成功 +1
         int ok = ackIndex + 1;
         break;
     case RECONSUME_LATER:// 失败 -1
         ackIndex = -1;
         break;
     default:
         break;
 }

switch (this.defaultMQPushConsumer.getMessageModel()) {
    case BROADCASTING:
        // print log 
        break;
    case CLUSTERING:
        List<MessageExt> msgBackFailed = new ArrayList<MessageExt>(consumeRequest.getMsgs().size());
        for (int i = ackIndex + 1; i < consumeRequest.getMsgs().size(); i++) {
            MessageExt msg = consumeRequest.getMsgs().get(i);
            boolean result = this.sendMessageBack(msg, context);// 消费失败，发送回去到 MQ
            if (!result) {
                msg.setReconsumeTimes(msg.getReconsumeTimes() + 1);
                msgBackFailed.add(msg);
            }
        }
        if (!msgBackFailed.isEmpty()) {// 发送到MQ失败，继续消费
            consumeRequest.getMsgs().removeAll(msgBackFailed);
            this.submitConsumeRequestLater(msgBackFailed, consumeRequest.getProcessQueue(), consumeRequest.getMessageQueue());
        }
        break;
    default:
        break;
}

// 更新 offset
long offset = consumeRequest.getProcessQueue().removeMessage(consumeRequest.getMsgs());
if (offset >= 0 && !consumeRequest.getProcessQueue().isDropped()) {
    // 这里会更新 offset 
    // 如果看实现（RemoteBrokerOffsetStore） 中的实现，仅仅是把内存中的 offset 进行更新
    // 并没有RPC或者执行文件刷盘等操作。
    // 而真正的同步 offset 是通过定时任务定期执行的(源码在 MQClientInstance#startScheduledTask 中)
    // 因此offset 的同步是存在时间差的，如果 consumer 被kill -9 了， offset 可能没有被更新，
    // 等 consumer 重启，依然会从旧的 offset 拉取消息进行消费，也就存在重复消费消息的可能。
    // 此处的offset 是和queue 一对一的
    this.defaultMQPushConsumerImpl.getOffsetStore().updateOffset(consumeRequest.getMessageQueue(), offset, true);
}

}
```

### sendMessageBack

sendMessageBack 的实现，Broker 实现细节可参考 [Broker消息重试逻辑](rocketmq-consumer-send-msg-back.md)

```java

// 首先通过 msg 获取Host地址，进行发送
// 通过 ConsumerSendMsgBackRequestHeader 把消息发送到Borker 进行存储
// Broker 中使用 MixAll.getRetryTopic 获取新的Topic 的名称
// 此外还是会判断消息是已经消费了最大的次数等等

// 上面的consumerSendMessageBack 方法异常之后，执行下面的逻辑
// 获取Topic 的名称，Topic 名称是 %RETRY% + ConsumerGroup 的组合
// 保存旧的msgId到Props中
// 更新 reconsumeTime
// 再次发送
public void sendMessageBack(MessageExt msg, int delayLevel, final String brokerName)
    throws RemotingException, MQBrokerException, InterruptedException, MQClientException {
    try {
        // 一次尝试发送消息到Broker
        String brokerAddr = (null != brokerName) ? this.mQClientFactory.findBrokerAddressInPublish(brokerName)
            : RemotingHelper.parseSocketAddressAddr(msg.getStoreHost());
        this.mQClientFactory.getMQClientAPIImpl().consumerSendMessageBack(brokerAddr, msg,
            this.defaultMQPushConsumer.getConsumerGroup(), delayLevel, 5000, getMaxReconsumeTimes());
    } catch (Exception e) {
        // 异常之后，第二次尝试再次发送消息
        log.error("sendMessageBack Exception, " + this.defaultMQPushConsumer.getConsumerGroup(), e);
        // Topic 名称是 %RETRY% + ConsumerGroup 的组合
        Message newMsg = new Message(MixAll.getRetryTopic(this.defaultMQPushConsumer.getConsumerGroup()), msg.getBody());
        String originMsgId = MessageAccessor.getOriginMessageId(msg);
        MessageAccessor.setOriginMessageId(newMsg, UtilAll.isBlank(originMsgId) ? msg.getMsgId() : originMsgId);
        newMsg.setFlag(msg.getFlag());
        MessageAccessor.setProperties(newMsg, msg.getProperties());
        MessageAccessor.putProperty(newMsg, MessageConst.PROPERTY_RETRY_TOPIC, msg.getTopic());
        MessageAccessor.setReconsumeTime(newMsg, String.valueOf(msg.getReconsumeTimes() + 1));
        MessageAccessor.setMaxReconsumeTimes(newMsg, String.valueOf(getMaxReconsumeTimes()));
        MessageAccessor.clearProperty(newMsg, MessageConst.PROPERTY_TRANSACTION_PREPARED);
        newMsg.setDelayTimeLevel(3 + msg.getReconsumeTimes());
        this.mQClientFactory.getDefaultMQProducer().send(newMsg);
    } finally {
        msg.setTopic(NamespaceUtil.withoutNamespace(msg.getTopic(), this.defaultMQPushConsumer.getNamespace()));
    }
}
```

### ProcessQueue

首先说下 `ProcessQueue` 的创建,代码在 RebalanceImpl 中。ProcessQueue（PullRequest）的创建，会在 重平衡之后，再次创建或者删除 PullRequest。

这里简单说下 重平衡(Rebalance)的作用，现实场景中，存在`Consumer`上线下线的过程（如应用发布）。如果新 consumer 上线了
它也需要分配一个 MessageQueue 进行消息的拉取消费。这里就是 Rebalance 的作用，重新分配 MessageQueue 让每个 Consumer 都可以拉取消息进行消费。
（Consumer 下线是一样的道理。下线的Consumer使用的MessageQueue需要分配给其他 Consumer 进行消费）

```java
// ProcessQueue 创建&与 PullRequest 绑定的代码片段
// RebalanceImpl#updateProcessQueueTableInRebalance
// 一个 MessageQueue 对应一个PullRequest （一个queue）
for (MessageQueue mq : mqSet) {
    if (!this.processQueueTable.containsKey(mq)) {
        // 创建 ProcessQueue
        ProcessQueue pq = new ProcessQueue();
        // ... 
        // 创建 PullRequest 绑定 ProcessQueue
        PullRequest pullRequest = new PullRequest();
        pullRequest.setConsumerGroup(consumerGroup);
        pullRequest.setNextOffset(nextOffset);
        pullRequest.setMessageQueue(mq);
        pullRequest.setProcessQueue(pq);// 设置 ProcessQueue
        pullRequestList.add(pullRequest);
    }
}
```

上面主要是说明 `ProcessQueue` : `PullRequest` = 1:1

其次再说 `ProcessQueue` 的作用，一个 `ProcessQueue` 对应 `PullRequest` 。在拉取消息之后，会把消息加入到 ProcessQueue 中。代码如下：

```java
// 添加消息
// DefaultMQPushConsumerImpl#pullMessage
boolean dispatchToConsume = processQueue.putMessage(pullResult.getMsgFoundList());
// 移除消息
// ConsumeMessageConcurrentlyService#processConsumeResult
long offset = consumeRequest.getProcessQueue().removeMessage(consumeRequest.getMsgs());
```

而在消息消费之后，会从 `ProcessQueue` 中移除。因此通过 `ProcessQueue` 可以知道有多少消息没有消费，判断消息是否产生了`积压`,
如果产生了`积压`，那就会暂定拉取消息。这是 Consumer 端控制消息积压的方式。具体的代码可以在 `DefaultMQPushConsumerImpl#pullMessage` 中找到。
(这里也回答了上面如果，消息消费过慢，可以通过 ProcessQueue 进行判断，把 pullRequest 放入到延迟线程池中。等待50ms之后再拉取消息)

## RebalancePushImpl#computePullFromWhere

现实场景中，如果消费者由于发布等原因，进行了重启。那么在重启之后，消息者需要知道从哪里消费消息（或者说从哪里拉取消息）。

而 `RebalancePushImpl#computePullFromWhere` 方法就是消费者从哪里开始消费的实现。

[computePullFromWhere 源码](https://github.com/apache/rocketmq/blob/master/client/src/main/java/org/apache/rocketmq/client/impl/consumer/RebalancePushImpl.java#L141)

```java
// 是否是第一次 pull Msg
if (!pullRequest.isLockedFirst()) {
         // 获取 offset
         final long offset = this.rebalanceImpl.computePullFromWhere(pullRequest.getMessageQueue());
         // 更新 offset
         pullRequest.setNextOffset(offset);
}
```

`computePullFromWhere` 的实现

```java
public long computePullFromWhere(MessageQueue mq) {
//...
switch (consumeFromWhere) {
    case CONSUME_FROM_LAST_OFFSET_AND_FROM_MIN_WHEN_BOOT_FIRST:// 废弃
    case CONSUME_FROM_MIN_OFFSET:// 废弃
    case CONSUME_FROM_MAX_OFFSET:// 废弃
    case CONSUME_FROM_LAST_OFFSET: {//case1
        break;
    }
    case CONSUME_FROM_FIRST_OFFSET: {//case2
        break;
    }
    case CONSUME_FROM_TIMESTAMP: {//case3
        break;
    }
}
// 上面的三个 case 都是执行 readOffset 方法，获取 lastOffset
// long lastOffset = offsetStore.readOffset(mq, ReadOffsetType.READ_FROM_STORE);
// case1: 如果是第一次消费(lastOffset=-1) 获取 getMQAdminImpl().maxOffset 否则使用 lastOffset
// case2: 如果是第一次消费,lastOffset=0,否则使用 lastOffset
// case3: 如果是第一次消费,getMQAdminImpl().searchOffset(mq,timestamp) 查找Offset，否则使用 lastOffset
```

获取 `offset` 的简单的代码流程：

```java
RemoteBrokerOffsetStore(OffsetStore) -> readOffset
-> MQClientInstance
-> MQClientAPIImpl -> queryConsumerOffset
-> QueryConsumerOffsetRequestHeader // 发送查询 Request
-> Borker // Borker 进行处理，发送 Response
-> QueryConsumerOffsetResponseHeader // 处理 Response
-> offset // 获取 offset
```

## Consumer 的负载均衡

### RebalanceImpl Consumer的重平衡

`Rebalance` 的实现（划线的已废弃）`Rebalance` 的作用主要是给`Client`按照一定的策略分配`Queue`

| ConsumerImpl                  | Rebalance             |
| ----------------------------- | --------------------- |
| DefaultMQPushConsumerImpl     | RebalancePushImpl     |
| DefaultLitePullConsumerImpl   | RebalanceLitePullImpl |
| ~~DefaultMQPullConsumerImpl~~ | ~~RebalancePullImpl~~ |

```java
// DefaultMQPushConsumerImpl
private final RebalanceImpl rebalanceImpl = new RebalancePushImpl(this);
```

核心方法

```java
public void doRebalance(final boolean isOrder) {
    Map<String, SubscriptionData> subTable = this.getSubscriptionInner();
    if (subTable != null) {
        for (final Map.Entry<String, SubscriptionData> entry : subTable.entrySet()) {
            final String topic = entry.getKey();
            try {
                this.rebalanceByTopic(topic, isOrder);
            } catch (Throwable e) {
                if (!topic.startsWith(MixAll.RETRY_GROUP_TOPIC_PREFIX)) {
                    log.warn("rebalanceByTopic Exception", e);
                }
            }
        }
    }
    this.truncateMessageQueueNotMyTopic();
}
```

```java
// rebalanceByTopic
// rebalanceByTopic 方法的主要作用就是执行 AllocateMessageQueueStrategy#allocate 方法
private void rebalanceByTopic(final String topic, final boolean isOrder) {

// ...
List<MessageQueue> allocateResult = null;
try {
    allocateResult = strategy.allocate(
        this.consumerGroup,
        this.mQClientFactory.getClientId(),
        mqAll,
        cidAll);
} catch (Throwable e) {
    log.error("AllocateMessageQueueStrategy.allocate Exception. allocateMessageQueueStrategyName={}", strategy.getName(),
        e);
    return;
}
// ...
}
```

下面继续看 `AllocateMessageQueueStrategy` 的分配策略

### MessageQueue 的分配策略

`AllocateMessageQueueStrategy` 是 `doRebalance` 中多个消费者如何分配 `MessageQueue` 的实现策略

- AllocateMachineRoomNearby
- AllocateMessageQueueAveragely
- AllocateMessageQueueAveragelyByCircle
- AllocateMessageQueueByConfig
- AllocateMessageQueueByMachineRoom
- AllocateMessageQueueConsistentHash

这里看下 `AllocateMessageQueueAveragely` 的分配实现(默认的Queue分配规则)。

```java
// allocate 方法的参数
// currentCID 当前的 clientId
// mqAll 所有的MessageQueue
// cidAll 所有的 clientId
public List<MessageQueue> allocate(String consumerGroup, 
                                   String currentCID, 
                                    List<MessageQueue> mqAll,
                                    List<String> cidAll) 
{

    // cidAll 和 mqAll 都是排序过的，因此可以保证，所有的Consumer Client 拿到的Client和MessageQueue列表顺序是一样的。
    List<MessageQueue> result = new ArrayList<MessageQueue>();
    int index = cidAll.indexOf(currentCID);// 
    int mod = mqAll.size() % cidAll.size();// MessageQueue数量 % Client数量，
    // mod>0 说明 queue的数量大于client的数量,比如：（可能是16个queue，3个client消费）
    // mod=0 ,此时：可能是16个queue，18个client消费
    // 1. 计算 averageSize
    //    如果 MessageQueue数量小于Client数量，说明Client数量多于queue数量，每个Client最多只能分配一个Queue
    //    mod>0 说明不是整除，如果 index小于mod，averageSize 需要整除+1
    //    举例：如果有0-15个Queue,有3个client,此时mod=1,每个client平均分配5个queue,还剩下一个queue,就按照顺序分配给以第一个Client(averageSize=5+1)6个Queue，
    //    而第一个Client的index=0 小于 (mod=1)
    // 2. 计算 startIndex,计算当前 currentCID 从哪里开始分配queue(0~15)
    //    (mod > 0 && index < mod)  mod > 0 有余数，不够平均分配,index < mod,说明是第一个Client,开始位置不需要加上余数mod
    // 3. 计算 range 分配的次数,index=0时，startIndex=0，使用  Math.min 计算正确的 range
    // 4. 根据次数range和startIndex分配queue
    int averageSize =
        mqAll.size() <= cidAll.size() ? 1 : (mod > 0 && index < mod ? mqAll.size() / cidAll.size()
            + 1 : mqAll.size() / cidAll.size());
    // index < mod,需要多分配一个queue,开始位置不需要加上 mod
    int startIndex = (mod > 0 && index < mod) ? index * averageSize : index * averageSize + mod;
    // min 方法的作用：如果queue=16,client=30，此时第18个Client（index * averageSize+mod =17*1+0=17）分配的queue 就是0
    int range = Math.min(averageSize, mqAll.size() - startIndex);
    for (int i = 0; i < range; i++) {
        result.add(mqAll.get((startIndex + i) % mqAll.size()));
    }
    return result;

}
```

分配结果图：

![rocketmq-consumer-AllocateMessageQueueAveragely.svg](./images/rocketmq-consumer-AllocateMessageQueueAveragely.svg)

Demo(做了简单的修改)测试如下：

```java
public class main {
    public static void main(String[] args) {

        List<String> cidAll = Arrays.asList("Client_1", "Client_2", "Client_3");
        List<Integer> mqAll = Arrays.asList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
        String consumerGroup = "TEST";

        Collections.sort(cidAll);
        Collections.sort(mqAll);

        allocate(consumerGroup, "Client_1", mqAll, cidAll).forEach(i -> System.out.print(i + ","));
        System.out.println();
        allocate(consumerGroup, "Client_2", mqAll, cidAll).forEach(i -> System.out.print(i + ","));
        System.out.println();
        allocate(consumerGroup, "Client_3", mqAll, cidAll).forEach(i -> System.out.print(i + ","));
    }

    public static List<Integer> allocate(String consumerGroup,
                                         String currentCID,
                                         List<Integer> mqAll,
                                         List<String> cidAll) {

        List<Integer> result = new ArrayList<Integer>();
        int index = cidAll.indexOf(currentCID);
        int mod = mqAll.size() % cidAll.size();

        int averageSize =
                mqAll.size() <= cidAll.size() ? 1 : (mod > 0 && index < mod ? mqAll.size() / cidAll.size()
                        + 1 : mqAll.size() / cidAll.size());
        int startIndex = (mod > 0 && index < mod) ? index * averageSize : index * averageSize + mod;
        int range = Math.min(averageSize, mqAll.size() - startIndex);
        for (int i = 0; i < range; i++) {
            result.add(mqAll.get((startIndex + i) % mqAll.size()));
        }
        return result;

    }
}
// Output:
// 0,1,2,3,4,5,
// 6,7,8,9,10,
// 11,12,13,14,15,
```

> 如果 Client 的数量大于Queue，那么多余的Client其实是无法分配到Queue的，也就没有办法进行消息的消费。
> 那么是否有方法解决Consumer的数量远远大于Queue的这种场景遇到的问题吗？解决思路也是很简单。就是通过加一层 MQ Proxy(MQ 客户端代理)
> 让 MQ Proxy 去连接Broker,业务服务的客户端只与MQ Proxy进行交互。这个可以支持更多的Consumer。
>  MQ Proxy 需要非常高的性能。

最后我们知道了，重平衡(rebalance)的主要作用就是给`Client`重新分配`Queue`,也就是`Consumer`端的负载均衡的实现入口。


## 总结

消息消费的概述：

- 1. 消费端进行重平衡分配到 MessageQueue ，根据它创建 PullRequest 和ProcessQueue
- 2. 异步线程进行根据 PullRequest 拉取消息，获取到 List<MessageExt> 列表
- 3. 交给业务线程进行 业务逻辑处理，此处的核心类：ConsumeMessageConcurrentlyService.ConsumeRequest，ConsumeMessageOrderlyService.ConsumeRequest
- 4. 更新消息的消费进度offset,以及处理消费失败的逻辑

## Links

- [消息订阅](https://cloud.tencent.com/developer/article/1474885)
- [消息队列模型](https://cloud.tencent.com/developer/article/1747568?)
- [RocketMQ 重平衡](rocketmq-rebalance.md)
- [平均分配算法](https://www.cnblogs.com/sinpo828/p/14264518.html)