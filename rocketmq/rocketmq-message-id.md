# Message id

![./images/rocketmq-message-id.drawio.svg](./images/rocketmq-message-id.drawio.svg)

在 RocketMQ 中 消息的MessageId包含了消息存储所在的 broker ip+port 信息，此外还有消息在文件中的偏移信息 offset。

这样做的好处就是只通过 messageId 就可以快速的查询到消息的内容(方便运维，排查问题)。

## MessageDecoder

MessageDecoder 负责messageid 的生成+解析。

```java
// 根据 addr地址 + offset物理偏移 创建 messageId
public static String createMessageId(final ByteBuffer input, final ByteBuffer addr, final long offset) {
    input.flip();
    int msgIDLength = addr.limit() == 8 ? 16 : 28;
    input.limit(msgIDLength);

    input.put(addr);
    input.putLong(offset);

    return UtilAll.bytes2string(input.array());
}

// String messageId 转换成 MessageId 对象
public static MessageId decodeMessageId(final String msgId) throws UnknownHostException {
    byte[] bytes = UtilAll.string2bytes(msgId);
    ByteBuffer byteBuffer = ByteBuffer.wrap(bytes);
    // address(ip+port)
    byte[] ip = new byte[msgId.length() == 32 ? 4 : 16];
    byteBuffer.get(ip);
    int port = byteBuffer.getInt();
    SocketAddress address = new InetSocketAddress(InetAddress.getByAddress(ip), port);
    // offset
    long offset = byteBuffer.getLong();
    return new MessageId(address, offset);
}
```

## MQClientAPIImpl viewMessage

查询消息 `viewMessage`，的实现就是 根据 messageId 中的broker 地址和offset 进行 RPC调用，查询到消息内容。

下面给出代码片段，方便理解。

```java

// MQClientAPIImpl#viewMessage
// 第一步根据messageId 解析出 addr（broker地址） + phyoffset（消息所在文件的物理偏移）
public MessageExt viewMessage(String msgId)
        throws RemotingException, MQBrokerException, InterruptedException, MQClientException {
        MessageId messageId = null;
        try {
            messageId = MessageDecoder.decodeMessageId(msgId);
        } catch (Exception e) {
            throw new MQClientException(ResponseCode.NO_MESSAGE, "query message by id finished, but no message.");
        }
        return this.mQClientFactory.getMQClientAPIImpl().viewMessage(NetworkUtil.socketAddress2String(messageId.getAddress()),
            messageId.getOffset(), timeoutMillis);
}

// MQClientAPIImpl#viewMessage
public MessageExt viewMessage(final String addr, final long phyoffset, final long timeoutMillis){
    // 发送 RemotingCommand 命令，查询消息
    ViewMessageRequestHeader requestHeader = new ViewMessageRequestHeader();
        requestHeader.setOffset(phyoffset);
        RemotingCommand request = RemotingCommand.createRequestCommand(RequestCode.VIEW_MESSAGE_BY_ID, requestHeader);

        RemotingCommand response = this.remotingClient.invokeSync(MixAll.brokerVIPChannel(this.clientConfig.isVipChannelEnabled(), addr),
            request, timeoutMillis);
    // 省略其他代码
}
```

## Links

- [https://cloud.tencent.com/developer/article/1581366](https://cloud.tencent.com/developer/article/1581366)