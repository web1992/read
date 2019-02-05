# MessageToMessageCodec

- [MessageToMessageCodec](#messagetomessagecodec)
  - [Decoder&Encoder](#decoderencoder)
  - [作用](#%E4%BD%9C%E7%94%A8)
  - [demo](#demo)

## Decoder&Encoder

- `MessageToMessageDecoder`
- `MessageToMessageEncoder`

通过下面二个类的相关的功能，分析`MessageToMessageCodec`的用法

- `StringDecoder`
- `StringEncoder`

## 作用

`StringDecoder`,`StringEncoder` 可以再 netty 中进行基于`String`类型的数据通信

- `StringDecoder` 把`ByteBuf`转化为`String`,把接受到的 byte 字节，转化为 String
- `StringEncoder` 把`String`转化为`ByteBuf`,把`String`转化为`byte`字节，进行网络的传输

## demo

Decodes a received `ByteBuf` into a String. Please note that this decoder must be used with a proper `ByteToMessageDecoder` such as `DelimiterBasedFrameDecoder` or `LineBasedFrameDecoder` if you are using a stream-based transport such as TCP/IP. A typical setup for a text-based line protocol in a TCP/IP socket would be:

```java
ChannelPipeline pipeline = ...;
// Decoders
pipeline.addLast("frameDecoder", new LineBasedFrameDecoder(80));
pipeline.addLast("stringDecoder", new StringDecoder(CharsetUtil.UTF_8));

// Encoder
pipeline.addLast("stringEncoder", new StringEncoder(CharsetUtil.UTF_8));

// and then you can use a String instead of a ByteBuf as a message:
void channelRead(ChannelHandlerContext ctx, String msg) {
     ch.write("Did you say '" + msg + "'?\n");
}
```
