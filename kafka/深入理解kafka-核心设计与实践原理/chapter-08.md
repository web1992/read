# 第8章 可靠性探究

- 多副本的机制
- 数据副本
- 服务副本
- 一致性协议
- 实现故障自动转移
- 失效副本
- replica.lag.time.max.ms
- ISR集合 ISR(in-sync Replica)
- under-replicated 分区
- LEO（LogEndOffset）
- lastCaughtUpTimeMs
- 启动一个副本过期检测的定时任务
- 本地副本（Local Replica）和远程副本（Remote Replica）
- FetchRequest fetch_offset
- 注意leader副本的HW是一个很重要的东西，因为它直接影响了分区数据对消费者的可见性。
- recovery-point-offset-checkpoint 和replication-offset-checkpoint 这两个文件分别对应了 LEO和 HW
- HW high_watermark
- Leader Epoch
- 截断数据

## 副本

副本（Replica）是分布式系统中常见的概念之一，指的是分布式系统对数据和服务提供的一种冗余方式。在常见的分布式系统中，为了对外提供可用的服务，我们往往会对数据和服务进行副本处理。数据副本是指在不同的节点上持久化同一份数据，当某一个节点上存储的数据丢失时，可以从副本上读取该数据，这是解决分布式系统数据丢失问题最有效的手段。

另一类副本是服务副本，指多个节点提供同样的服务，每个节点都有能力接收来自外部的请求并进行相应的处理。

组成分布式系统的所有计算机都有可能发生任何形式的故障。一个被大量工程实践所检验过的`黄金定理`：任何在设计阶段考虑到的异常情况，一定会在系统实际运行中发生，并且在系统实际运行过程中还会遇到很多在设计时未能考虑到的异常故障。所以，除非需求指标允许，否则在系统设计时不能放过任何异常情况。

核心概念：

- 副本是相对于分区而言的，即副本是特定分区的副本。
- 一个分区中包含一个或多个副本，其中一个为`leader副本`，其余为`follower副本`，各个副本位于不同的broker节点中。只有leader副本对外提供服务，follower副本只负责数据同步。
- 分区中的所有副本统称为 AR，而ISR 是指与leader 副本保持同步状态的副本集合，当然leader副本本身也是这个集合中的一员。
- LEO标识每个分区中最后一条消息的下一个位置，分区的每个副本都有自己的LEO，ISR中最小的LEO即为HW，俗称高水位，消费者只能拉取到HW之前的消息。

从生产者发出的一条消息首先会被写入分区的leader副本，不过还需要等待ISR集合中的所有 follower 副本都同步完之后才能被认为已经提交，之后才会更新分区的 HW，进而消费者可以消费到这条消息。

## 失效副本

- 允许的最大时间差 replica.lag.time.max.ms
- 消息数超过 replica.lag.max.messages 已经废弃的参数，受到TPS大小的影响，没有实际意义

正常情况下，分区的所有副本都处于ISR集合中，但是难免会有异常情况发生，从而某些副本被剥离出ISR集合中。在ISR集合之外，也就是处于同步失效或功能失效（比如副本处于非存活状态）的副本统称为失效副本，失效副本对应的分区也就称为同步失效分区，即under-replicated分区。

Kafka源码注释中说明了一般有两种情况会导致副本失效：
- follower副本进程卡住，在一段时间内根本没有向leader副本发起同步请求，比如频繁的Full GC。
- follower副本进程同步过慢，在一段时间内都无法追赶上leader副本，比如I/O开销过大。

## 副本同步过程

整个消息追加的过程可以概括如下：
- （1）生产者客户端发送消息至leader副本（副本1）中。
- （2）消息被追加到leader副本的本地日志，并且会更新日志的偏移量。
- （3）follower副本（副本2和副本3）向leader副本请求同步数据。
- （4）leader副本所在的服务器读取本地日志，并更新对应拉取的follower副本的信息。
- （5）leader副本所在的服务器将拉取结果返回给follower副本。
- （6）follower副本收到leader副本返回的拉取结果，将消息追加到本地日志中，并更新日志的偏移量信息。


## LEO和 HW

recovery-point-offset-checkpoint 和replication-offset-checkpoint 这两个文件分别对应了 LEO和 HW。Kafka 中会有一个定时任务负责将所有分区的 LEO 刷写到恢复点文件 recovery-point-offset-checkpoint 中，定时周期由 broker 端参数 log.flush.offset.checkpoint.interval.ms来配置，默认值为60000。还有一个定时任务负责将所有分区的HW刷写到复制点文件replication-offset-checkpoint中，定时周期由broker端参数replica.high.watermark.checkpoint.interval.ms来配置，默认值为5000。

log-start-offset-checkpoint文件对应logStartOffset（注意不能缩写为LSO，因为在Kafka中LSO是LastStableOffset的缩写），这个在5.4.1节中就讲过，在FetchRequest和FetchResponse中也有它的身影，它用来标识日志的起始偏移量。各个副本在变动 LEO 和 HW 的过程中，logStartOffset 也有可能随之而动。Kafka 也有一个定时任务来负责将所有分区的 logStartOffset书写到起始点文件log-start-offset-checkpoint中，定时周期由broker端参数log.flush.start.offset.checkpoint.interval.ms来配置，默认值为60000。


## HW 更新

follower副本各自拉取到了消息，并更新各自的LEO为3和4。与此同时，follower副本还会更新自己的HW，更新HW的算法是比较当前LEO和leader副本中传送过来的HW的值，取较小值作为自己的HW值。当前两个follower副本的HW都等于0（min（0，0）=0）。

接下来follower副本再次请求拉取leader副本中的消息，如图8-6所示。

此时leader副本收到来自follower副本的FetchRequest请求，其中带有LEO的相关信息，选取其中的最小值作为新的HW，即min（15，3，4）=3。然后连同消息和HW一起返回FetchResponse给follower副本，如图8-7所示。注意leader副本的HW是一个很重要的东西，因为它直接影响了分区数据对消费者的可见性。

```txt
leader LEO=15
follower1 LEO=3
follower2 LEO=4

HW=即min（15，3，4）=3。
```

两个follower副本在收到新的消息之后更新LEO并且更新自己的HW为3（min（LEO，3）=3）。

总结：

```txt
leader   HW = Min(leader.LEO,follower1.LEO,follower1.LEO)
follower HW = Min(leader.HW,follower.LEO)
```
