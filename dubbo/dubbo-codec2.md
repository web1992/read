# Codec2

## Codec2 interface

```java
@SPI
public interface Codec2 {

    @Adaptive({Constants.CODEC_KEY})
    void encode(Channel channel, ChannelBuffer buffer, Object message) throws IOException;

    @Adaptive({Constants.CODEC_KEY})
    Object decode(Channel channel, ChannelBuffer buffer) throws IOException;


    enum DecodeResult {
        NEED_MORE_INPUT, SKIP_SOME_INPUT
    }

}
```

## DubboCodec

![DubboCodec](./images/dubbo-DubboCodec.png)

## DecodeHandler

支持 `Decodeable`

## 好文链接

- [dubbo-protocol](http://dubbo.incubator.apache.org/zh-cn/blog/dubbo-protocol.html)