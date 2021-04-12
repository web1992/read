# Consumer

- [Consumer](#consumer)
  - [Consumer start](#consumer-start)
  - [消息的创建和消费](#消息的创建和消费)
  - [消息消费的核心类](#消息消费的核心类)
  - [MQClientInstance](#mqclientinstance)
    - [MQClientInstance#selectConsumer](#mqclientinstanceselectconsumer)
    - [MQClientInstance 中的定时任务](#mqclientinstance-中的定时任务)
    - [MQClientInstance PullMessageService](#mqclientinstance-pullmessageservice)
  - [ConsumeMessageConcurrentlyService](#consumemessageconcurrentlyservice)
    - [consumeMessageDirectly](#consumemessagedirectly)
    - [ConsumeRequest](#consumerequest)
  - [ProcessQueue](#processqueue)
  - [RebalanceImpl](#rebalanceimpl)
  - [PullCallback](#pullcallback)
  - [PullAPIWrapper pullKernelImpl](#pullapiwrapper-pullkernelimpl)
  - [PullMessageRequestHeader](#pullmessagerequestheader)
  - [RemotingClient](#remotingclient)
  - [PullMessageProcessor](#pullmessageprocessor)
  - [PullMessageService](#pullmessageservice)
  - [DefaultLitePullConsumer](#defaultlitepullconsumer)
  - [DefaultMQPushConsumer](#defaultmqpushconsumer)

可以了解的内容：

- Consumer 消费消息的流程
- Consumer 消费消息失败了，怎么处理
- Consumer 在重启之后，如何继续上一次消费的位置，继续处理
- Consumer 为什么需要重平衡(rebalance)的

## Consumer start

消息消费者的启动过程：

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

## 消息的创建和消费

![messgae flow](images/rocketmq-consumer-create-consumer.png)

## 消息消费的核心类

![rocketmq-consumer-class](./images/rocketmq-consumer.png)

- DefaultMQPushConsumer （consumer 入口）负责 consumer 的启动&管理配置参数
- DefaultMQPushConsumerImpl 核心实现类，包含 ConsumeMessageService 和 MQClientInstance
- MQClientInstance 负责底层的通信
- ConsumeMessageService 负责处理消息服务

## MQClientInstance

### MQClientInstance#selectConsumer

### MQClientInstance 中的定时任务

- MQClientInstance.this.mQClientAPIImpl.fetchNameServerAddr();
- MQClientInstance.this.updateTopicRouteInfoFromNameServer();
- MQClientInstance.this.cleanOfflineBroker();
- MQClientInstance.this.sendHeartbeatToAllBrokerWithLock();
- MQClientInstance.this.persistAllConsumerOffset();
- MQClientInstance.this.adjustThreadPool();

### MQClientInstance PullMessageService

```java
// PullMessageService 的定义，继承了 ServiceThread
public class PullMessageService extends ServiceThread {

}
// PullRequest 阻塞队列
private final LinkedBlockingQueue<PullRequest> pullRequestQueue = new LinkedBlockingQueue<PullRequest>();
private final MQClientInstance mQClientFactory;
// scheduledExecutorService 支持延迟的 PullRequest 
// 就是在一定时间之后，再把 PullRequest 放入到 pullRequestQueue 队列中
private final ScheduledExecutorService scheduledExecutorService = Executors
    .newSingleThreadScheduledExecutor(new ThreadFactory() {
        @Override
        public Thread newThread(Runnable r) {
            return new Thread(r, "PullMessageServiceScheduledThread");
        }
    });

// run 方法
@Override
public void run() {
    log.info(this.getServiceName() + " service started");
    while (!this.isStopped()) {
        try {
            PullRequest pullRequest = this.pullRequestQueue.take();
            this.pullMessage(pullRequest);
        } catch (InterruptedException ignored) {
        } catch (Exception e) {
            log.error("Pull Message Service Run Method exception", e);
        }
    }
    log.info(this.getServiceName() + " service end");
}

// pullMessage
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

## ConsumeMessageConcurrentlyService

### consumeMessageDirectly

### ConsumeRequest

## ProcessQueue

## RebalanceImpl

## PullCallback

## PullAPIWrapper pullKernelImpl

## PullMessageRequestHeader

## RemotingClient

```java
// RemotingClient 的初始化
public MQClientAPIImpl(final NettyClientConfig nettyClientConfig,
    final ClientRemotingProcessor clientRemotingProcessor,
    RPCHook rpcHook, final ClientConfig clientConfig) {
    this.clientConfig = clientConfig;
    topAddressing = new TopAddressing(MixAll.getWSAddr(), clientConfig.getUnitName());
    this.remotingClient = new NettyRemotingClient(nettyClientConfig, null);
    this.clientRemotingProcessor = clientRemotingProcessor;
    this.remotingClient.registerRPCHook(rpcHook);
    this.remotingClient.registerProcessor(RequestCode.CHECK_TRANSACTION_STATE, this.clientRemotingProcessor, null);
    this.remotingClient.registerProcessor(RequestCode.NOTIFY_CONSUMER_IDS_CHANGED, this.clientRemotingProcessor, null);
    this.remotingClient.registerProcessor(RequestCode.RESET_CONSUMER_CLIENT_OFFSET, this.clientRemotingProcessor, null);
    this.remotingClient.registerProcessor(RequestCode.GET_CONSUMER_STATUS_FROM_CLIENT, this.clientRemotingProcessor, null);
    this.remotingClient.registerProcessor(RequestCode.GET_CONSUMER_RUNNING_INFO, this.clientRemotingProcessor, null);
    this.remotingClient.registerProcessor(RequestCode.CONSUME_MESSAGE_DIRECTLY, this.clientRemotingProcessor, null);
    this.remotingClient.registerProcessor(RequestCode.PUSH_REPLY_MESSAGE_TO_CLIENT, this.clientRemotingProcessor, null);
}
```

## PullMessageProcessor

`org.apache.rocketmq.broker.processor.PullMessageProcessor`

## PullMessageService

## DefaultLitePullConsumer

## DefaultMQPushConsumer
