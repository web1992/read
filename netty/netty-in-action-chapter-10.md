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

## MessageToMessageDecoder

## TooLongFrameException

## Encoders


## MessageToByteEncoder

## MessageToMessageEncoder