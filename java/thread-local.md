# ThreadLocal

- [ThreadLocal](#threadlocal)
  - [initialValue](#initialvalue)
  - [set](#set)
  - [get](#get)
  - [ThreadLocal-gc](#threadlocal-gc)
  - [ThreadLocalMap](#threadlocalmap)
    - [ThreadLocalMap key](#threadlocalmap-key)
    - [ThreadLocalMap value](#threadlocalmap-value)
  - [io.netty.util.concurrent.FastThreadLocal](#ionettyutilconcurrentfastthreadlocal)
  - [参考资料](#%E5%8F%82%E8%80%83%E8%B5%84%E6%96%99)

## initialValue

## set

## get

## ThreadLocal-gc

## ThreadLocalMap

`ThreadLocalMap` 是 `ThreadLocal` 的内部类, `ThreadLocalMap` 使用 `hash` 算法,存储数据

### ThreadLocalMap key

### ThreadLocalMap value

## io.netty.util.concurrent.FastThreadLocal

不得不说的  `io.netty.util.concurrent.FastThreadLocal` Netty 中对 `java.lang.ThreadLocal` 的优化

## 参考资料

- [ThreadLocl (github)](https://github.com/CL0610/Java-concurrency/blob/master/17.%E5%B9%B6%E5%8F%91%E5%AE%B9%E5%99%A8%E4%B9%8BThreadLocal/%E5%B9%B6%E5%8F%91%E5%AE%B9%E5%99%A8%E4%B9%8BThreadLocal.md)
- [ThreadLocl (简书)](https://www.jianshu.com/p/dde92ec37bd1)
- [threadLocal 内存泄漏的原因](https://stackoverflow.com/questions/17968803/threadlocal-memory-leak)
- [threadLocal 优化](https://www.cnblogs.com/zhjh256/p/6367928.html)
