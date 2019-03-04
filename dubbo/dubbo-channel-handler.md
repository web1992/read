# ChannelHandler

`dubbo` 中的 `ChannelHandler` 用来处理所有 IO 相关的事件,编码，解码，序列化，反序列化

常见的 handler:

- DubboProtocol#ExchangeHandler
- HeaderExchangeHandler
- DecodeHandler
- MultiMessageHandler
- HeartbeatHandler
- AllChannelHandler
- NettyServerHandler
- NettyServer

`dubbo` 服务器端的 `handler` 链:

- decoder
  - encoder
    - IdleStateHandler
      - NettyServerHandler
        - NettyServer
          - MultiMessageHandler
            - HeartbeatHandler
              - AllChannelHandler
                - DecodeHandler
                  - HeaderExchangeHandler
                    - DubboProtocol#requestHandler

`dubbo` 客户端端的 `handler` 链:

- decoder
  - encoder
    - IdleStateHandler
      - NettyClientHandler
        - NettyClient
              - MultiMessageHandler
                  - HeartbeatHandler
                      - AllChannelHandler
                          - DecodeHandler
                              - HeaderExchangeHandler
                                  - DubboProtocol#requestHandler

## DecodeHandler

![DecodeHandler](images/dubbo-DecodeHandler.png)

## AllChannelHandler

![AllChannelHandler](images/dubbo-AllChannelHandler.png)

## HeaderExchangeHandler