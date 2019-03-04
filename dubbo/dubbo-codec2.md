# Codec2

`dubbo` 中的协议是通过 `head + body` 组成的变长协议

`Codec2` 解决的问题：

1. 半包，粘包 的问题
2. head 解析
3. body 解析
4. body 长度
5. 对象序列化
6. 对象放序列化

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