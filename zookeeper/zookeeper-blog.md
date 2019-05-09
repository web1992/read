# blog

- [zk 应用场景](https://www.ibm.com/developerworks/cn/opensource/os-cn-zookeeper/)
- [zab](https://blog.csdn.net/u013679744/article/details/79240249)
- [cap](https://tech.youzan.com/cap-coherence-protocol-and-application-analysis/)
- [cap](https://blog.csdn.net/qq_28165595/article/details/81211733)

## CAP

CAP协议又称CAP定理，指的是在一个分布式系统中，Consistency（一致性）、 Availability（可用性）、Partition tolerance（分区容错性），三者不可得兼。
分布式系统的CAP理论：理论首先把分布式系统中的三个特性进行了如下归纳：

- 一致性（C）：在分布式系统中的所有数据备份，在同一时刻是否同样的值。（等同于所有节点访问同一份最新的数据副本）
- 可用性（A）：在集群中一部分节点故障后，集群整体是否还能响应客户端的读写请求。（对数据更新具备高可用性）
- 分区容错性（P）：以实际效果而言，分区相当于对通信的时限要求。系统如果不能在时限内达成数据一致性，就意味着发生了分区的情况，必须就当前操作在C和A之间做出选择。在进行分布式架构设计时，必须做出取舍。而对于分布式数 据系统，分区容忍性是基本要求 ，否则就失去了价值。因此设计分布式数据系统，就是在一致性和可用性之间取一个平衡。
