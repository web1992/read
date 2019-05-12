# Zookeeper Atomic Broadcast

`ZAB` `Zookeeper` 原子消息广播协议

## 问题描述

- 分布式数据一致性问题
- 优雅的处理故障，并从故障中恢复

## 算法描述

二个过程：

- 消息广播
- 崩溃恢复

三个阶段：

- 发现 -> leader 选举过程
- 同步
- 广播
