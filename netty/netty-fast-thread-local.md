# FastThreadLocal

`Netty` 中使用 `FastThreadLocal` 对 `ThreadLocal` 进行了优化

- 1. 替换（优化） hash table
- 2. 解决内存泄漏的方法
