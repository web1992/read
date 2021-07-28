# CHAPTER 10

- An overview of decoders, encoders and codecs
- Netty’s codec classes

- [CHAPTER 10](#chapter-10)
  - [codec](#codec)
  - [Decoders](#decoders)
  - [ByteToMessageDecoder](#bytetomessagedecoder)
  - [ReplayingDecoder](#replayingdecoder)
  - [MessageToMessageDecoder](#messagetomessagedecoder)
  - [TooLongFrameException](#toolongframeexception)
  - [Encoders](#encoders)
  - [MessageToByteEncoder](#messagetobyteencoder)
  - [MessageToMessageEncoder](#messagetomessageencoder)
  - [ByteToMessageCodec](#bytetomessagecodec)
  - [MessageToMessageCodec](#messagetomessagecodec)
  - [CombinedChannelDuplexHandler](#combinedchannelduplexhandler)

## codec

Think of a message as a structured sequence of bytes having meaning for a specific
application—its data. An encoder converts that message to a format suitable for trans-
mission (most likely a byte stream); the corresponding decoder converts the network
stream back to the program’s message format. An `encoder`, then, operates on `outbound`
data and a `decoder` handles `inbound` data.

## Decoders

- Decoding bytes to messages— `ByteToMessageDecoder` and `ReplayingDecoder`
- Decoding one message type to another— `MessageToMessageDecoder`

## ByteToMessageDecoder

Decoding from bytes to messages (or to another sequence of bytes) is such a common
task that Netty provides an abstract base class for it: `ByteToMessageDecoder` . Since you
can’t know whether the remote peer will send a complete message all at once, this
class buffers inbound data `until it’s ready for processing`

example

```java
public class ToIntegerDecoder extends ByteToMessageDecoder {
    @Override
    public void decode(ChannelHandlerContext ctx, ByteBuf in,
        List<Object> out) throws Exception {
        if (in.readableBytes() >= 4) {
            out.add(in.readInt());
        }
    }
}
```

You might find it a bit `annoying` to have to verify that the input ByteBuf has enough data for
you to call `readInt()` . In the next section we’ll discuss `ReplayingDecoder` , a special
decoder that eliminates this step, at the cost of a small amount of overhead.

> Reference counting in codecs

As we mentioned in chapters 5 and 6, reference counting requires special attention.
In the case of encoders and decoders, the procedure is quite simple: once a mes-
sage has been encoded or decoded, it will automatically be released by a call to
ReferenceCountUtil.release(message) . If you need to keep a reference for later
use you can call ReferenceCountUtil.retain(message) . This increments the reference count, preventing the message from being released.

## ReplayingDecoder

`public abstract class ReplayingDecoder<S> extends ByteToMessageDecoder`

Simple guideline: use ByteToMessageDecoder if it doesn’t introduce excessive complexity;
otherwise, use ReplayingDecoder.

More decoders

The following classes handle more complex use cases:

- `io.netty.handler.codec.LineBasedFrameDecoder` —This class, used internally by Netty, uses end-of-line control characters ( \n or \r\n ) to parse the message data.
- `io.netty.handler.codec.http.HttpObjectDecoder` —A decoder for HTTP data.

You’ll find additional encoder and decoder implementations for special use cases in
the subpackages of io.netty.handler.codec . Please consult the Netty Javadoc for
more information.

## MessageToMessageDecoder

In this section we’ll explain how to convert between message formats (for example,
from one type of POJO to another) using the abstract base class

```java
public abstract class MessageToMessageDecoder<I> extends ChannelInboundHandlerAdapter
{
    decode(ChannelHandlerContext ctx,I msg,List<Object> out);
}
```

HttpObjectAggregator For a more complex example, please examine the class `io.netty.handler.codec.http.HttpObjectAggregator` , which extends `MessageToMessageDecoder<HttpObject>`

## TooLongFrameException

## Encoders

Netty provides a set of classes to help you to write encoders
with the following capabilities:

- Encoding from messages to bytes
- Encoding from messages to messages

## MessageToByteEncoder

```java
public class ShortToByteEncoder extends MessageToByteEncoder<Short> {
    @Override
    public void encode(ChannelHandlerContext ctx, Short msg, ByteBuf out)
        throws Exception {
        out.writeShort(msg);
    }
}
```

## MessageToMessageEncoder

```java
public class IntegerToStringEncoder
    extends MessageToMessageEncoder<Integer> {
    @Override
    public void encode(ChannelHandlerContext ctx, Integer msg,
        List<Object> out) throws Exception {
        out.add(String.valueOf(msg));
    }
}
```

## ByteToMessageCodec

## MessageToMessageCodec

## CombinedChannelDuplexHandler
