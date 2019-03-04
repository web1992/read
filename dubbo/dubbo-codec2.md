# Codec2

`dubbo` 中的协议是通过 `head + body` 组成的变长协议

`Codec2` 解决的作用：

1. 半包 粘包
2. head 解析
3. body 解析
4. body 长度
5. 对象序列化
6. 对象反序列化

`org.apache.dubbo.remoting.Codec2` 实现类：

> 按照模块分类

- transport
  - org.apache.dubbo.remoting.transport.AbstractCodec
  - org.apache.dubbo.remoting.transport.codec.TransportCodec
  - org.apache.dubbo.remoting.transport.codec.CodecAdapter
- protocol
  - org.apache.dubbo.rpc.protocol.dubbo.DubboCountCodec
  - org.apache.dubbo.rpc.protocol.dubbo.DubboCodec
- exchange
  - org.apache.dubbo.remoting.exchange.codec.ExchangeCodec
- telnet
  - org.apache.dubbo.remoting.telnet.codec.TelnetCodec

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

类图：

![dubbo-codec2](images/dubbo-codec2.png)

## DubboCountCodec

`DubboCountCodec` 对 `DubboCodec` 进行了简单的包装，提供了计数的功能

## DubboCodec

![DubboCodec](./images/dubbo-DubboCodec.png)

## DecodeHandler

支持 `Decodeable`

## 好文链接

- [dubbo-protocol](http://dubbo.incubator.apache.org/zh-cn/blog/dubbo-protocol.html)
