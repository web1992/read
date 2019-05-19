# ChannelBuffer

> `org.apache.dubbo.remoting.transport.netty4.ChannelBuffer` 是参照 `Netty` 的 `ChannelBuffer` 的实现
>
> Netty 3.0 `org.jboss.netty.buffer.ChannelBuffer`

## uml

![ChannelBuffer](images/dubbo-ChannelBuffer.png)

在 `dubbo` 中的 `ChannelBuffer` 的实现类是 `org.apache.dubbo.remoting.transport.netty4.NettyBackedChannelBuffer`

## decode init

```java
// NettyCodecAdapter -> InternalDecoder
private class InternalDecoder extends ByteToMessageDecoder {
    @Override
    protected void decode(ChannelHandlerContext ctx, ByteBuf input, List<Object> out) throws Exception {
        // 这里把 io.netty.buffer.ByteBuf 包装成了 NettyBackedChannelBuffer
        ChannelBuffer message = new NettyBackedChannelBuffer(input);
        NettyChannel channel = NettyChannel.getOrAddChannel(ctx.channel(), url, handler);
        try {
            // decode object.
            do {
                int saveReaderIndex = message.readerIndex();
                Object msg = codec.decode(channel, message);
                if (msg == Codec2.DecodeResult.NEED_MORE_INPUT) {
                    message.readerIndex(saveReaderIndex);
                    break;
                } else {
                    //is it possible to go here ?
                    if (saveReaderIndex == message.readerIndex()) {
                        throw new IOException("Decode without read data.");
                    }
                    if (msg != null) {
                        out.add(msg);
                    }
                }
            } while (message.readable());
        } finally {
            NettyChannel.removeChannelIfDisconnected(ctx.channel());
        }
    }
}
```

## encode init

```java
// NettyCodecAdapter -> InternalEncoder
private class InternalEncoder extends MessageToByteEncoder {
    @Override
    protected void encode(ChannelHandlerContext ctx, Object msg, ByteBuf out) throws Exception {
         // 这里把 io.netty.buffer.ByteBuf 包装成了 NettyBackedChannelBuffer
        org.apache.dubbo.remoting.buffer.ChannelBuffer buffer = new NettyBackedChannelBuffer(out);
        Channel ch = ctx.channel();
        NettyChannel channel = NettyChannel.getOrAddChannel(ch, url, handler);
        try {
            codec.encode(channel, buffer, msg);
        } finally {
            NettyChannel.removeChannelIfDisconnected(ch);
        }
    }
}
```
