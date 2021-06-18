# MessageExt

RocketMQ  如何存储（持久化）消息

## MessageExt 的序列化存储

`MessageExt` 的序列化存储，从 `Producer` 创建的`Msg`，会被 borker 包装成 `MessageExt` 对象 本文分析 `MessageExt` 是如何存储的在文件中的,

除了 `Msg` 的 `Body`，`Topic`，`Tags` 等信息，还存储了那些额外的信息？以及存储这些额外信息的作用。

## 先上图

以 `MessageExtBrokerInner` 为例,消息的存储格式:

![rocket-store-msg.png](./images/rocket-store-msg.png)

上图是根据 `org.apache.rocketmq.store.CommitLog` 中内部类 `DefaultAppendMessageCallback` 源码绘制。

## 核心字段讲解

### queueId

```java
// MessageExt
private int queueId;

// CommitLog#DefaultAppendMessageCallback
// 4 QUEUEID
this.msgStoreItemMemory.putInt(msgInner.getQueueId());

```

### queueOffset

```java
private boolean putBackHalfMsgQueue(MessageExt msgExt, long offset) {
    PutMessageResult putMessageResult = putBackToHalfQueueReturnResult(msgExt);
    if (putMessageResult != null
        && putMessageResult.getPutMessageStatus() == PutMessageStatus.PUT_OK) {
        msgExt.setQueueOffset(// queueOffset
            putMessageResult.getAppendMessageResult().getLogicsOffset());// queueOffset
        msgExt.setCommitLogOffset(// commitLogOffset
            putMessageResult.getAppendMessageResult().getWroteOffset());// wroteOffset
        msgExt.setMsgId(putMessageResult.getAppendMessageResult().getMsgId());
        log.debug(
            "Send check message, the offset={} restored in queueOffset={} "
                + "commitLogOffset={} "
                + "newMsgId={} realMsgId={} topic={}",
            offset, msgExt.getQueueOffset(), msgExt.getCommitLogOffset(), msgExt.getMsgId(),
            msgExt.getUserProperty(MessageConst.PROPERTY_UNIQ_CLIENT_MESSAGE_ID_KEYIDX),
            msgExt.getTopic());
        return true;
    } else {
        log.error(
            "PutBackToHalfQueueReturnResult write failed, topic: {}, queueId: {}, "
                + "msgId: {}",
            msgExt.getTopic(), msgExt.getQueueId(), msgExt.getMsgId());
        return false;
    }
}
```

`AppendMessageResult`

```java
// AppendMessageResult
// PHY OFFSET
long wroteOffset = fileFromOffset + byteBuffer.position();

Long queueOffset = CommitLog.this.topicQueueTable.get(key);

AppendMessageResult result = new AppendMessageResult(AppendMessageStatus.PUT_OK, wroteOffset, msgLen, msgId,
    msgInner.getStoreTimestamp(), queueOffset, CommitLog.this.defaultMessageStore.now() - beginTimeMills);
// logicsOffset=queueOffset
// wroteOffset=wroteOffset
```

### msgId

### reconsumeTimes

### sysFlag

### preparedTransactionOffset

### commitLogOffset

## Message PROPERTY
