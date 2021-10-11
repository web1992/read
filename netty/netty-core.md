# Netty 核心

| 说明                                            | 相关的类                                                                |
| ----------------------------------------------- | ----------------------------------------------------------------------- |
| Netty 的启动和配置 (服务端+客户端的启动)        | Bootstrap and ServerBootstrap                                           |
| Netty 的（I/O）事件处理机制(Netty 的流水线设计) | NioEventLoop ，ChannelHandler， ChannelPipeline ，ChannelHandlerContext |
| Netty 的内存分配                                | ByteBuf，Unpooled                                                       |
| Netty 的编码，解码                              | ByteToMessageDecoder ，MessageToByteEncoder                             |
| Netty + Java NIO                                | Netty 中对 NIO 的封装，抽象，优化                                       |

## Netty 设计思想

- Reactor 线程模型（设计模式）

## Links

- [Reactor pattern 设计模式](https://en.wikipedia.org/wiki/Reactor_pattern)
- [Reactor 线程模型](https://cloud.tencent.com/developer/article/1647816)
- [Reactor VS Proactor](https://jishuin.proginn.com/p/763bfbd58a63)
- [小白教程](https://www.jianshu.com/p/eb28811421e3)
