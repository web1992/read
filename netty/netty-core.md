# Netty 核心

从 Netty 的架构设计角度去看

| 说明                                            | 相关的类                                                                |
| ----------------------------------------------- | ----------------------------------------------------------------------- |
| Netty 的启动和配置 (服务端+客户端的启动) 设计   | Bootstrap and ServerBootstrap                                           |
| Netty 的（I/O）事件处理机制(Netty 的流水线设计) | NioEventLoop ，ChannelHandler， ChannelPipeline ，ChannelHandlerContext |
| Netty 的内存分配 设计                           | ByteBuf，Unpooled，PoolArena，PoolChunk，PoolChunkList，PoolSubpage     |
| Netty 的编码，解码 设计                         | ByteToMessageDecoder ，MessageToByteEncoder                             |
| Netty + Java NIO 设计                           | Netty 中对 NIO 的封装，抽象，优化                                       |

从 Netty 相关使用流程角度去看

- Netty 服务端启动的流程（建立监听）
- Netty 客户端启动的流程 （建立连接）
- Netty 数据读取的流程
- Netty 写数据的流程

## Netty 设计思想

- Reactor 线程模型（设计模式）

## Netty 的算法

- 伙伴算法，避免内存分配的碎片

## Links

- [Reactor pattern 设计模式](https://en.wikipedia.org/wiki/Reactor_pattern)
- [Reactor 线程模型](https://cloud.tencent.com/developer/article/1647816)
- [Reactor VS Proactor](https://jishuin.proginn.com/p/763bfbd58a63)
- [小白教程](https://www.jianshu.com/p/eb28811421e3)
- [Netty 写数据缓冲 ChannelOutboundBuffer](https://www.cnblogs.com/stateis0/p/9062155.html)
- [SizeClasses](https://www.codetd.com/article/12644429)
- [Netty 中的内存分配浅析](https://www.cnblogs.com/rickiyang/p/13100413.html)
- [Netty 内存池化管理](https://miaowenting.site/2020/02/09/Netty%E5%86%85%E5%AD%98%E6%B1%A0%E5%8C%96%E7%AE%A1%E7%90%86/)
- [Netty PoolArena](https://gorden5566.com/post/1079.html)
- [Chunk](https://www.jianshu.com/p/70181af2972a)