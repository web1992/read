# FastThreadLocal

`Netty` 中使用 `FastThreadLocal` 对 `ThreadLocal` 进行了优化

## ThreadLocal

关于 `ThreadLocal` 可以参考这个 [ThreadLocal](../java/thread-local.md)

`ThreadLocal` 中最主要的方法是 `initialValue`,`set`,`get`

`ThreadLocal` 中使用 `ThreadLocalMap` 来存储信息,底层使用 `Entry[]` + `hashcode` 来存储数据

使用 `hashcode` 带来的文件就是会产生 hash 冲突，产生 hash 冲突之后，会形成链接。导致 `get` 方法的效率降低

`Netty` 中使用类似 `ArrayList` 的`索引`来解决这个问题

## InternalThreadLocalMap

## FastThreadLocalThread

## FastThreadLocal get

## FastThreadLocal initialize

## FastThreadLocal set
