# rocketmq tx

了解`RocketMQ`事务的实现细节。

## 概述

RocketMQ 事务的流程图

![rocket-mq-tx.png](./images/rocket-mq-tx.png)

关键字：

- RMQ_SYS_TRANS_HALF_TOPIC `半`消息 topic

## TransactionalMessageService

`org.apache.rocketmq.broker.transaction.TransactionalMessageService` 的方法列表,从方法可知道，RockeMQ需要处理的逻辑，可与上图做对比。

| 方法                 | 描述                                   |
| -------------------- | -------------------------------------- |
| prepareMessage       | 发送事务消息的时候执行的方法           |
| asyncPrepareMessage  | 异步的发送事务消息                     |
| deletePrepareMessage | 删除事务消息，事务失败，就会执行此方法 |
| commitMessage        | 事务的提交                             |
| rollbackMessage      | 事务的回滚                             |
| check                | 检查事务的状态                         |
| open                 | nop                                    |
| close                | nop                                    |

下面从下面的几个维度去看事务消息的实现细节：

- Client 对事务消息的发送处理
- Broker 对事务消息的特殊处理
- Clinet 事务结束（提交or回滚）的实现逻辑
- Broker 事务的回查询（查询事务状态）的实现逻辑

## Client 端发送事物消息

需要使用事务消息，则需要两个步骤：

- Create the transactional producer: 使用`事务`Producer发送消息
- Implement the TransactionListener interface: 实现 TransactionListener 来处理事务回调和查询

```java
// DefaultMQProducerImpl#sendMessageInTransaction
// 事务消息的发送
public TransactionSendResult sendMessageInTransaction(final Message msg,
    final LocalTransactionExecuter localTransactionExecuter, final Object arg)
    throws MQClientException {
    TransactionListener transactionListener = getCheckListener();
    if (null == localTransactionExecuter && null == transactionListener) {
        throw new MQClientException("tranExecutor is null", null);
    }
    // ignore DelayTimeLevel parameter
    if (msg.getDelayTimeLevel() != 0) {
        MessageAccessor.clearProperty(msg, MessageConst.PROPERTY_DELAY_TIME_LEVEL);
    }
    // ...
    Validators.checkMessage(msg, this.defaultMQProducer);
    SendResult sendResult = null;
    // 事务消息的特殊处理
    MessageAccessor.putProperty(msg, MessageConst.PROPERTY_TRANSACTION_PREPARED, "true");// 新增 prop
    MessageAccessor.putProperty(msg, MessageConst.PROPERTY_PRODUCER_GROUP, this.defaultMQProducer.getProducerGroup());
    // ... 发送消息
    sendResult = this.send(msg);
    // ...
    this.endTransaction(sendResult, localTransactionState, localException);
    TransactionSendResult transactionSendResult = new TransactionSendResult();
    transactionSendResult.setSendStatus(sendResult.getSendStatus());
    transactionSendResult.setMessageQueue(sendResult.getMessageQueue());
    transactionSendResult.setMsgId(sendResult.getMsgId());
    transactionSendResult.setQueueOffset(sendResult.getQueueOffset());
    transactionSendResult.setTransactionId(sendResult.getTransactionId());
    transactionSendResult.setLocalTransactionState(localTransactionState);
    return transactionSendResult;
}
```

[sendMessageInTransaction 完整的代码](https://github.com/apache/rocketmq/blob/master/client/src/main/java/org/apache/rocketmq/client/impl/producer/DefaultMQProducerImpl.java#L1202)

```java
// DefaultMQProducerImpl#sendKernelImpl
// 如果是事务消息，那么就添加事务消息的标记，
final String tranMsg = msg.getProperty(MessageConst.PROPERTY_TRANSACTION_PREPARED);// 校验 prop
if (tranMsg != null && Boolean.parseBoolean(tranMsg)) {
    sysFlag |= MessageSysFlag.TRANSACTION_PREPARED_TYPE;  
}
```

发送事务消息的时候，会在 prop 中添加 `PROPERTY_TRANSACTION_PREPARED` 属性，同时根据此属性来设置 `sysFlag` 标记此消息是事务消息。
上面的代码执行之后，消息就会通过 `sendKernelImpl` 方法，发送到了 Borker,下面的代码是 Borker 执行事务消息存储的逻辑

## Broker 端存储事物消息

```java
// SendMessageProcessor#asyncSendMessage
// 事务消息 prop 的判断
String transFlag = origProps.get(MessageConst.PROPERTY_TRANSACTION_PREPARED);
if (transFlag != null && Boolean.parseBoolean(transFlag)) {// 判断标记
    // 执行事务消息的逻辑
    putMessageResult = this.brokerController.getTransactionalMessageService().asyncPrepareMessage(msgInner);
} else {
    // 普通消息的逻辑
    putMessageResult = this.brokerController.getMessageStore().asyncPutMessage(msgInner);
}

// 下面的代码 是 Broker 处理事务消息的代码步骤：
// putMessageResult = this.brokerController.getTransactionalMessageService().asyncPrepareMessage(msgInner);
// put 消息 步骤1
public CompletableFuture<PutMessageResult> asyncPrepareMessage(MessageExtBrokerInner messageInner) {
    return transactionalMessageBridge.asyncPutHalfMessage(messageInner);
}
// put 消息 步骤2
public CompletableFuture<PutMessageResult> asyncPutHalfMessage(MessageExtBrokerInner messageInner) {
    return store.asyncPutMessage(parseHalfMessageInner(messageInner));// 包装消息，并使调用 store 存储
}
// put 消息 步骤3
private MessageExtBrokerInner parseHalfMessageInner(MessageExtBrokerInner msgInner) {
    MessageAccessor.putProperty(msgInner, MessageConst.PROPERTY_REAL_TOPIC, msgInner.getTopic());
    MessageAccessor.putProperty(msgInner, MessageConst.PROPERTY_REAL_QUEUE_ID,
        String.valueOf(msgInner.getQueueId()));
    msgInner.setSysFlag(
        MessageSysFlag.resetTransactionValue(msgInner.getSysFlag(), MessageSysFlag.TRANSACTION_NOT_TYPE));
    msgInner.setTopic(TransactionalMessageUtil.buildHalfTopic());// RMQ_SYS_TRANS_HALF_TOPIC 修改 topic
    msgInner.setQueueId(0);
    msgInner.setPropertiesString(MessageDecoder.messageProperties2String(msgInner.getProperties()));
    return msgInner;
}
```

通过上面的代码可知，事务消息，最终会把`事务消息`存储在 `RMQ_SYS_TRANS_HALF_TOPIC` Topic 中。事务和非事务消息 最终都会通过 `MessageStore` -> `CommitLog` -> `MappedFile` -> `File` 存储在文件系统中。

## Client 端继续处理事物消息

当事务消息被发送到 Broker 之后，Client 就开始去校验本地事务的状态，然后来确定是`提交`还是`回滚`事务。
下面是处理本地事务的逻辑。

```java
// DefaultMQProducerImpl#endTransaction
// 根据本地事务的状态，去结束事务
public void endTransaction(
    final SendResult sendResult,
    final LocalTransactionState localTransactionState,
    final Throwable localException) throws RemotingException, MQBrokerException, InterruptedException, UnknownHostException {

    EndTransactionRequestHeader requestHeader = new EndTransactionRequestHeader();
    requestHeader.setTransactionId(transactionId);
    requestHeader.setCommitLogOffset(id.getOffset());
    // 本地事务的状态
    switch (localTransactionState) {
        case COMMIT_MESSAGE:// 事务提交
            requestHeader.setCommitOrRollback(MessageSysFlag.TRANSACTION_COMMIT_TYPE);
            break;
        case ROLLBACK_MESSAGE:// 事务回滚
            requestHeader.setCommitOrRollback(MessageSysFlag.TRANSACTION_ROLLBACK_TYPE);
            break;
        case UNKNOW:// 未知
            requestHeader.setCommitOrRollback(MessageSysFlag.TRANSACTION_NOT_TYPE);
            break;
        default:
            break;
    }
    requestHeader.setProducerGroup(this.defaultMQProducer.getProducerGroup());
    requestHeader.setTranStateTableOffset(sendResult.getQueueOffset());
    requestHeader.setMsgId(sendResult.getMsgId());
    String remark = localException != null ? ("executeLocalTransactionBranch exception: " + localException.toString()) : null;
    // 事务结束
    this.mQClientFactory.getMQClientAPIImpl().endTransactionOneway(brokerAddr, requestHeader, remark,
        this.defaultMQProducer.getSendMsgTimeout());
}

// DefaultMQProducerImpl#endTransaction
// 下面的代码把 事务结束的信息通过  RemotingCommand 发送到 borker, RequestCode=END_TRANSACTION
public void endTransactionOneway(
    final String addr,
    final EndTransactionRequestHeader requestHeader,
    final String remark,
    final long timeoutMillis
) throws RemotingException, MQBrokerException, InterruptedException {
    RemotingCommand request = RemotingCommand.createRequestCommand(RequestCode.END_TRANSACTION, requestHeader);
    request.setRemark(remark);
    this.remotingClient.invokeOneway(addr, request, timeoutMillis);// 发送到 broker
}
```

## EndTransactionProcessor

Broker 会处理事务消息的提交 / 事务消息的回滚。 `EndTransactionProcessor` 是 Borker 处理事务消息回滚和提交的入口。

```java
// EndTransactionProcessor#processRequest
// 下面的代码主要处理事物的提交+事物的回滚操作
public RemotingCommand processRequest(ChannelHandlerContext ctx, RemotingCommand request) throws
    RemotingCommandException {
    final RemotingCommand response = RemotingCommand.createResponseCommand(null);
    final EndTransactionRequestHeader requestHeader =
        (EndTransactionRequestHeader)request.decodeCommandCustomHeader(EndTransactionRequestHeader.class);
    // 省略一些检查代码
    OperationResult result = new OperationResult();
    if (MessageSysFlag.TRANSACTION_COMMIT_TYPE == requestHeader.getCommitOrRollback()) {
        // ...省略 
        result = this.brokerController.getTransactionalMessageService().commitMessage(requestHeader); // 事务提交
        if (res.getCode() == ResponseCode.SUCCESS) {
            MessageExtBrokerInner msgInner = endMessageTransaction(result.getPrepareMessage());
            msgInner.setSysFlag(MessageSysFlag.resetTransactionValue(msgInner.getSysFlag(), requestHeader.getCommitOrRollback()));
            msgInner.setQueueOffset(requestHeader.getTranStateTableOffset());
            msgInner.setPreparedTransactionOffset(requestHeader.getCommitLogOffset());
            msgInner.setStoreTimestamp(result.getPrepareMessage().getStoreTimestamp());
            MessageAccessor.clearProperty(msgInner, MessageConst.PROPERTY_TRANSACTION_PREPARED);
            RemotingCommand sendResult = sendFinalMessage(msgInner);// 发送消息
            // this.brokerController.getMessageStore().putMessage(msgInner);
            if (sendResult.getCode() == ResponseCode.SUCCESS) {
                this.brokerController.getTransactionalMessageService().deletePrepareMessage(result.getPrepareMessage());
            }
            return sendResult;
        }
    } else if (MessageSysFlag.TRANSACTION_ROLLBACK_TYPE == requestHeader.getCommitOrRollback()) {
         // ...省略 
        result = this.brokerController.getTransactionalMessageService().rollbackMessage(requestHeader);// 事务回滚
        if (result.getResponseCode() == ResponseCode.SUCCESS) {
            RemotingCommand res = checkPrepareMessage(result.getPrepareMessage(), requestHeader);
            if (res.getCode() == ResponseCode.SUCCESS) {
                // 删除消息
                this.brokerController.getTransactionalMessageService().deletePrepareMessage(result.getPrepareMessage());
            }
            return res;
        }
    }
    response.setCode(result.getResponseCode());
    response.setRemark(result.getResponseRemark());
    return response;
}
```

从上面的代码片段可知：事务的提交，最终是(再次发送消息)把消息发送到了真正的 topic 中，从 `RMQ_SYS_TRANS_HALF_TOPIC` tpoic 到真正的 topic
而事务回滚则是`删除消息`。

上面已经梳理了，事务提交+事务回滚的流程，下面的`TransactionalMessageCheckService` 类主要是针对异常的事务，进行补偿的实现（就是由Broker RPC业务client,查询事务的最终状态）

Broker 端补偿事物。

## TransactionalMessageCheckService 事务服务的初始化

```java
// BrokerController#initialTransaction
// transactionalMessageService 事务消息的实现类
// transactionalMessageCheckListener 事务消息的检查回调（负责处理事务状态查询）
// transactionalMessageCheckService 是一个线程,主要作用的检查事务的状态（开启事务状态查询的入口）
private void initialTransaction() {
    this.transactionalMessageService = ServiceProvider.loadClass(ServiceProvider.TRANSACTION_SERVICE_ID, TransactionalMessageService.class);
    if (null == this.transactionalMessageService) {
        this.transactionalMessageService = new TransactionalMessageServiceImpl(new TransactionalMessageBridge(this, this.getMessageStore()));
        log.warn("Load default transaction message hook service: {}", TransactionalMessageServiceImpl.class.getSimpleName());
    }
    this.transactionalMessageCheckListener = ServiceProvider.loadClass(ServiceProvider.TRANSACTION_LISTENER_ID, AbstractTransactionalMessageCheckListener.class);
    if (null == this.transactionalMessageCheckListener) {
        this.transactionalMessageCheckListener = new DefaultTransactionalMessageCheckListener();
        log.warn("Load default discard message hook service: {}", DefaultTransactionalMessageCheckListener.class.getSimpleName());
    }
    this.transactionalMessageCheckListener.setBrokerController(this);
    this.transactionalMessageCheckService = new TransactionalMessageCheckService(this);
}
```

## TransactionalMessageService#check

事务消息的查询策略：

- 1.定时任务 `TransactionalMessageCheckService` 会定期的执行查询事务状态得任务(TransactionalMessageService)
- 2.通过 Offset 查询事务消息，
- 3.根据 "d" in tags ,过滤已经 commit / rollback 的消息
- 4.执行查询逻辑 listener.resolveHalfMsg(msgExt);
- 5.最后更新 offset

```java
// offset
// halfOffset 事务消息的 ConsumeOffset,每次从这里开始查询事务消息
// opOffset
long halfOffset = transactionalMessageBridge.fetchConsumeOffset(messageQueue);
long opOffset = transactionalMessageBridge.fetchConsumeOffset(opQueue);
```

```java
// 根据 opOffset halfOffset 查询事务消息。
// 如果已经 commit / rollback 的消息会加入到 removeMap 中
PullResult pullResult = fillOpRemoveMap(removeMap, opQueue, opOffset, halfOffset, doneOpOffset);
```

事务消息的删除逻辑如下：

```java
@Override
public boolean deletePrepareMessage(MessageExt msgExt) {
    // 添加 tags=d,标记次消息”删除“ 也就是事务成功了
    if (this.transactionalMessageBridge.putOpMessage(msgExt, TransactionalMessageUtil.REMOVETAG)) { // REMOVETAG = "d";
        log.debug("Transaction op message write successfully. messageId={}, queueId={} msgExt:{}", msgExt.getMsgId(), msgExt.getQueueId(), msgExt);
        return true;
    } else {
        log.error("Transaction op message write failed. messageId is {}, queueId is {}", msgExt.getMsgId(), msgExt.getQueueId());
        return false;
    }
}
```

最后更新 offset

```java
// 更新 offset
if (newOffset != halfOffset) {
    transactionalMessageBridge.updateConsumeOffset(messageQueue, newOffset);
}
long newOpOffset = calculateOpOffset(doneOpOffset, opOffset);
if (newOpOffset != opOffset) {
    transactionalMessageBridge.updateConsumeOffset(opQueue, newOpOffset);
}
```

- RMQ_SYS_TRANS_OP_HALF_TOPIC

## AbstractTransactionalMessageCheckListener 发事务消息查询 Request

```java
// AbstractTransactionalMessageCheckListener#sendCheckMessage
// 此方法发送消息到 Client 查询事务状态
public void sendCheckMessage(MessageExt msgExt) throws Exception {
    CheckTransactionStateRequestHeader checkTransactionStateRequestHeader = new CheckTransactionStateRequestHeader();
    checkTransactionStateRequestHeader.setCommitLogOffset(msgExt.getCommitLogOffset());
    checkTransactionStateRequestHeader.setOffsetMsgId(msgExt.getMsgId());
    checkTransactionStateRequestHeader.setMsgId(msgExt.getUserProperty(MessageConst.PROPERTY_UNIQ_CLIENT_MESSAGE_ID_KEYIDX));
    checkTransactionStateRequestHeader.setTransactionId(checkTransactionStateRequestHeader.getMsgId());
    checkTransactionStateRequestHeader.setTranStateTableOffset(msgExt.getQueueOffset());
    msgExt.setTopic(msgExt.getUserProperty(MessageConst.PROPERTY_REAL_TOPIC));
    msgExt.setQueueId(Integer.parseInt(msgExt.getUserProperty(MessageConst.PROPERTY_REAL_QUEUE_ID)));
    msgExt.setStoreSize(0);
    String groupId = msgExt.getProperty(MessageConst.PROPERTY_PRODUCER_GROUP);
    Channel channel = brokerController.getProducerManager().getAvailableChannel(groupId);
    if (channel != null) {
        brokerController.getBroker2Client().checkProducerTransactionState(groupId, channel, checkTransactionStateRequestHeader, msgExt);
    } else {
        LOGGER.warn("Check transaction failed, channel is null. groupId={}", groupId);
    }
}
```

当 `Client` 收到消息的时候，会执行下面的代码流程，执行检查事务消息的逻辑。

`ClientRemotingProcessor.checkTransactionState` -> `transactionCheckListener.checkLocalTransactionState`

## Links

- [RocketMQ 事务消息架构(官方文档)](https://rocketmq.apache.org/rocketmq/the-design-of-transactional-message/)
- [https://rocketmq.apache.org/docs/transaction-example/](https://rocketmq.apache.org/docs/transaction-example/)
