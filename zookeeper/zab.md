# Zookeeper Atomic Broadcast

`ZAB` `Zookeeper` 原子消息广播协议

关键字：

- Leader 主
- Follwer 从
- proposal 提议
- 崩溃恢复 选举Leader
- 消息广播 数据同步
- 事物ID ZXID
- 高效的Leader选举算法
- 在Leader 或者 Follwer 崩溃恢复的时候，需要有一种方法知道是恢复事物，还是回滚事物（对于没完成的事物）
- 选举出来的Leader服务器拥有集群中所有机器最高编号(即ZXID最大)的事务Proposal
- epoch
- 发现(Discovery)
- 同步(Synchronization)
- 广播(Broadcast)
- LOOKING: Leader 选举阶段
- FOLLOWING:Follower服务器和Leader保持同步状态
- LEADING:Leader服务器作为主进程领导状态

## 问题描述

- 分布式数据一致性问题
- 优雅的处理故障，并从故障中恢复

## ZAB

ZAB协议的核心是定义了对于那些会改变ZooKeeper服务器数据状态的事务请求的处理方式，即:

所有事务请求必须由一个全局唯一的服务器来协调处理，这样的服务器被称为Leader服务器，而余下的其他服务器则成为Follower 服务器。
Leader 服务器负责将一个客户端事务请求转换成一个事务Proposal (提议)，并将该Proposal 分发给集群中所有的Follower服务器。
之后Leader 服务器需要等待所有Follower 服务器的反馈，一旦超过半数的Follower服务器进行了正确的反馈后，那么Leader就会再次向所有的Follower服务器分发Commit消息，要求其将前一个Proposal进行提交。

## ZXID

![zookeeper-zxid.drawio.svg](./images/zookeeper-zxid.drawio.svg)

上面讲到的是正常情况下的数据同步逻辑，下面来看ZAB协议是如何处理那些需要被丢弃的事务Proposal 的。在ZAB协议的事务编号ZXID设计中，
ZXID是一个64位的数字，其中低32位可以看作是一个简单的单调递增的计数器，针对客户端的每一个事务请求，Leader 服务器在产生一个新的事Proposal 的时候，都会对该计数器进行加1操作;而高32位则代表了Leader 周期epoch的编号，每当选举产生一个新的Leader服务器，就会从这个Leader服务器上取出其本地日志中最大事务Proposal的ZXID,并从该ZXID中解析出对应的epoch值，然后再对其进行加1操作，之后就会以此编号作为新的epoch，并将低32位置0来开始生成新的ZXID。ZAB协议中的这一通过epoch编号来区分Leader周期变化的策略，能够有效地避免不同的Leader服务器错误地使用相同的ZXID编号提出不一样的事务Proposal的异常情况，这对于识别在Leader崩溃恢复前后生成的Proposal非常有帮助，大大简化和提升了数据恢复流程。

完成Leader选举以及数据同步之后，ZAB协议就进入了原子广播阶段。在这一阶段中，Leader会以队列的形式为每一个与自己保持同步的Follower创建一个操作队列。同一时刻，一个Follower只能和一个Leader保持同步，Leader 进程与所有的Follower进程之间都通过心跳检测机制来感知彼此的情况。如果Leader能够在超时时间内正常收到心跳检测，那么Follower就会一直与该Leader保持连接。而如果在指定的超时时间内Leader无法从过半的Follower 进程那里接收到心跳检测，或者是TCP连接本身断开了，那么Leader就会终止对当前周期的领导，并转换到LOOKING状态，所有的Follower也会选择放弃这个Leader，同时转换到LOOKING状态。之后，所有进程就会开始新一轮的Leader选举，并在选举产生新的Leader之后开始新一轮的主进程周期。
