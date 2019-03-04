# ChannelHandler

`dubbo` 中的 `ChannelHandler` 用来处理所有 IO 相关的事件的转发：编码，解码，序列化，反序列化

> 实现类预览：

![ChannelHandler](images/dubbo-channel-handler-all.png)

`ChannelHandler` 使用了包装类，常见的 handler:

> 按照模块分类

- protocol
  - org.apache.dubbo.rpc.protocol.dubbo.DubboProtocol.ExchangeHandler
- exchange
  - org.apache.dubbo.remoting.exchange.support.header.HeaderExchangeHandler
  - org.apache.dubbo.remoting.exchange.support.header.HeartbeatHandler
- transport
  - org.apache.dubbo.remoting.transport.DecodeHandler
  - org.apache.dubbo.remoting.transport.MultiMessageHandler
  - org.apache.dubbo.remoting.transport.dispatcher.all.AllChannelHandler
  - org.apache.dubbo.remoting.transport.netty4.NettyServerHandler
  - org.apache.dubbo.remoting.transport.netty4.NettyServer
  - org.apache.dubbo.remoting.transport.netty4.NettyClientHandler
  - org.apache.dubbo.remoting.transport.netty4.NettyClient

`dubbo` 服务器端的 `handler` 链:

服务器端的事件从 `decoder` -> `DubboProtocol#requestHandler`

```java
Netty
-> decoder
  -> encoder
    -> IdleStateHandler
      -> NettyServerHandler
        -> NettyServer
          -> MultiMessageHandler
            -> HeartbeatHandler
              -> AllChannelHandler
                -> DecodeHandler
                  -> HeaderExchangeHandler
                    -> DubboProtocol#requestHandler
```

`dubbo` 客户端端的 `handler` 链:

```java
Netty
-> decoder
  -> encoder
    -> IdleStateHandler
      -> NettyClientHandler
        -> NettyClient
          -> MultiMessageHandler
            -> HeartbeatHandler
              -> AllChannelHandler
                -> DecodeHandler
                  -> HeaderExchangeHandler
                    -> DubboProtocol#requestHandler
```

客户端端的事件从 `decoder` -> `DubboProtocol#requestHandler`

## DecodeHandler

![DecodeHandler](images/dubbo-DecodeHandler.png)

## AllChannelHandler

![AllChannelHandler](images/dubbo-AllChannelHandler.png)

## HeaderExchangeHandler
