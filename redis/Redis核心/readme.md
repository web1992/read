# Redis 核心

- CPU 使用上的“坑”，例如数据结构的复杂度、跨 CPU 核的访问；
- 内存使用上的“坑”，例如主从同步和 AOF 的内存竞争；
- 存储持久化上的“坑”，例如在 SSD 上做快照的性能抖动；
- 网络通信上的“坑”，例如多实例时的异常网络丢包。
- 应用使用的问题
- 操作系统使用的问题
- `两大维度`就是指系统维度和应用维度
- 高性能主线，包括线程模型、数据结构、持久化、网络框架；
- 高可靠主线，包括主从复制、哨兵机制；
- 高可扩展主线，包括数据分片、负载均衡。
- Redis 同时使用了两种策略来删除过期的数据，分别是惰性删除策略和定期删除策略。


## Redis cmd

- [https://redis.com.cn/commands.html](https://redis.com.cn/commands.html)