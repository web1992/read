# PoolArena

PoolArena 是 Netty 内存管理的入口。学习源码可以从此类开始。

关键类：

- PooledByteBufAllocator
- PoolArena
- PoolSubpage
- PoolChunkList
- PoolChunk
- PoolSubpage
- PoolThreadCache

上面关键类的`组织`图:

![poolarena-poolarena.svg](./images/poolarena-poolarena.svg) 

图片来自: [https://gorden5566.com/post/1079.html](https://gorden5566.com/post/1079.html)

## Links

- [Netty 内存管理源码分析 jemalloc](https://www.jianshu.com/p/550704d5a628)
- [Netty Recycler源码解析](https://www.jianshu.com/p/8f629e93dd8c)