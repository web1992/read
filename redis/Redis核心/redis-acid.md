# Redis ACID

- 原子性（Atomicity）
- 一致性（Consistency）
- 隔离性（Isolation）
- 持久性（Durability）
- MULTI 开启一个事务
- EXEC 提交事务，从命令队列中取出提交的操作命令，进行实际执行
- WATCH 机制 检测一个或多个键的值在事务执行期间是否发生变化，如果发生变化，那么当前事务放弃执行
- DISCARD放弃一个事务，清空命令队列
- RDB 不会在事务执行时执行

## Consistency

可以理解一致性就是，应用系统从一个正确的状态到另一个正确的状态，而ACID就是说事务能够通过AID来保证这个C的过程。C是`目的`，AID都是`手段`。
