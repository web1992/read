# Netty in action

`Netty in action` 笔记

- [draw.io](draw.io/netty-in-action.xml)
- [Netty in action (source code with the book)](https://github.com/normanmaurer/netty-in-action)
- [netty.io](http://netty.io/)
- [user-guide-for-4.x](https://netty.io/wiki/user-guide-for-4.x.html)
- [关于 Netty 的文章](https://netty.io/wiki/related-articles.html)

![components](./images/components.png)

## Chapter List

- [Chapter List](netty-inaction.md)

## Summary

- [Summary](netty-in-action-summary.md)

## 源码分析

源码版本：[4.1.31.Final](https://github.com/netty/netty/releases/tag/netty-4.1.31.Final)

Netty 3 与 Netty 4 的实现是进行过大量修改的

`Netty in action` 英文版随书源码：[netty-in-action](https://github.com/normanmaurer/netty-in-action)

- [Bootstrap](source-code-bootstrap.md)
- [NioEventLoop](source-code-event-loop.md)
- [NioServerSocketChannel](source-code-channel.md)
- [ChannelPipeline](source-code-channel-pipeline.md)
- [ByteToMessageDecoder](source-code-byte-to-message-decoder.md)
- [ChannelFuture](source-code-channel-future.md)
- [Channel](source-code-channel.md)
- [MessageToMessageCodec](source-code-message-to-message-codec.md)

## 实战

- [基于 Netty 的服务器&客户端的序列化 demo](https://github.com/web1992/java_note/tree/master/app_tools/src/main/java/cn/web1992/utils/demo/netty/serializable)
