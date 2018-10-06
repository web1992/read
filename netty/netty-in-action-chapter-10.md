# CHAPTER 10

## codec

## Decoders

## ByteToMessageDecoder

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

## ReplayingDecoder

simple guideline: use ByteToMessageDecoder if it doesn’t introduce excessive complexity;
otherwise, use ReplayingDecoder.

## MessageToMessageDecoder

In this section we’ll explain how to convert between message formats (for example,
from one type of POJO to another) using the abstract base class

```java
public abstract class MessageToMessageDecoder<I>
extends ChannelInboundHandlerAdapter
```

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