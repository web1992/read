# TCP 的超时与重传

关键字：

- RTT（Round-Trip Time 往返时延)
- RTO （Retransmission TimeOut） 重传超时时间
- 指数退避(exponential backoff)
- 接收窗口「rwnd」
- cwnd 拥塞窗口
- ssthresh （阈值）
- 拥塞避免算法 (congestion avoidance)
- 快速重传与快速恢复算法 (fast retransmit,fast recovery)
- 慢启动 (slow start)
- 快速重传（Fast Retransmit）机制
- SACK （Selective Acknowledgment 选择性确认）
- Duplicate SACK
- 窗口关闭 发送窗口等于0

TCP 提供可靠的运输层。它使用的方法之一就是确认从另一端收到的数据。但数据和确认都有可能会丢失。TCP 通过在发送时设置一个定时器来解决这种问题。
如果当定时器溢出时还没有收到确认，它就重传该数据。对任何实现而言，关键之处就在于超时和重传的策略，即怎样决定超时间隔和如何确定重传的频率。

## 定时器

超时和重传的例子：

- a. 在 6 节的 ICMP 端口不能到达的例子中，看到 TFTP 客户使用 UDP 实现了一个简单的超时和重传机制：
  假定 5 秒是一个适当的时间间隔，并每隔 5 秒进行重传；
- b. 在向一个不存在的主机发送 ARP 的时候.我们看到当 TCP 试图建立连接的时候，在每个重传之间使用一个较长的时延来重传 SYN。

对每个连接，TCP 管理 4 个不同的定时器。

1. 重传定时器使用于当希望收到另一端的确认。在本章我们将详细讨论这个定时器以及一些相关的问题，如拥塞避免。
2. 坚持(persist)定时器使窗口大小信息保持不断流动，即使另一端关闭了其接收窗口。
3. 保活(keepalive)定时器可检测到一个空闲连接的另一端何时崩溃或重启。
4. 2MSL 定时器测量一个连接处于 TIMEWAIT 状态的时间。

## 往返时间测量

[Jacobson1988]详细分析了在 RTT 变化范围很大时，使用这个方法无法跟上这种变化，从而引起不必要的重传。
正如 Jacobson 记述的那样，当网络已经处于饱和状态时，不必要的重传会增加网络的负载，对网络而言这就像在火上浇油一样。

除了被平滑的 RTT 估计器，所需要做的还有跟踪 RTT 的方差。在往返时间变化起伏很大时，
基于均值和方差来计算 RTO，将比作为均值的常数倍数来计算 RTO 能提供更好的响应

## 拥塞避免算法

慢启动算法是在一个连接上发起数据流的方法，但有时我们会达到中间路由器的极限，此时分组将被丢弃。拥塞避免算法是一种处理丢失分组的方法。

该算法假定由于分组受到损坏引起的丢失是非常少的（远小于 1 %），因此分组丢失就意味着在源主机和目的主机之间的某处网络上发生了拥塞。有两种分组丢失的指示：`发生超时`和`接收到重复的确认`。

拥塞避免算法和慢启动算法是两个目的不同、独立的算法。但是当拥塞发生时，我们希望降低分组进入网络的传输速率，于是可以调用慢启动来作到这一点。在实际中这两个算法通常在`一起实现`。

拥塞避免算法和慢启动算法需要对每个连接维持两个变量：一个拥塞窗口 cwnd 和一个慢启动门限 ssthresh。这样得到的算法的工作过程如下：

1. 对一个给定的连接，初始化 cwnd 为 1 个报文段，ssthresh 为 65535 个字节。
2. TCP 输出例程的输出不能超过 cwnd 和接收方通告窗口的大小。拥塞避免是发送方使用的流量控制，而通告窗口则是接收方进流量控制。前者是发送方感受到的网络拥塞的估计，而后者则与接收方在该连接上的可用缓存大小有关。
3. 当拥塞发生时（超时或收到重复确认），ssthresh 被设置为当前窗口大小的一半(cwnd)和接收方通告窗口大小的最小值，但最少为 2 个报文段）。此外，如果是超时引起了拥塞，则cwnd 被设置为 1 个报文段（这就是慢启动）。
4. 当新的数据被对方确认时，就增加 cwnd，但增加的方法依赖于我们是否正在进行慢启动或拥塞避免。如果 cwnd 小于或等于 ssthresh，则正在进行慢启动，否则正在进行拥塞避免。慢启动一直持续到我们回到当拥塞发生时所处位置的半时候才停止（因为我们记录了在步骤 2中给我们制造麻烦的窗口大小的一半），然后转为执行拥塞避免。

慢启动算法初始设置 cwnd 为 1 个报文段，此后每收到一个确认就加 1。那样，这会使窗口按指数方式增长：发送 1 个报文段，然后是 2 个，接着是 4 个 ⋯⋯。

拥塞避免算法要求每次收到一个确认时将 cwnd 增加 1/cwnd。与慢启动的指数增加比起来，这是一种加性增长(additive increase)。我们希望在一个往返时间内最多为 cwnd 增加 1 个报文段（不管在这个 RTT 中收到了多少个 ACK），然而慢启动将根据这个往返时间中所收到的确认的个数增加 cwnd。

## 快速重传与快速恢复算法

在介绍修改之前，我们认识到在收到一个失序的报文段时，TCP 立即需要产生一个 ACK（一个重复的 ACK）。这个重复的 ACK 不应该被迟延。该重复的 ACK 的目的在于让对方知道收到一个失序的报文段，并告诉对方自己希望收到的序号。

由于我们不知道一个重复的 ACK 是由一个丢失的报文段引起的，还是由于仅仅出现了几个报文段的重新排序，因此我们等待少量重复的 ACK 到来。假如这只是一些报文段的重新排
序，则在重新排序的报文段被处理并产生一个新的 ACK 之前，只可能产生 1~2 个重复的 ACK。如果一连串收到 3 个或 3 个以上的重复 ACK，就非常可能是一个报文段丢失了。

于是我们就重传丢失的数据报文段，而无需等待超时定时器溢出。这就是**快速重传算法**。接下来执行的不是慢启动算法而是拥塞避免算法。这就是**快速恢复算法**。

在这种情况下没有执行慢启动的原因是由于收到重复的 ACK 不仅仅告诉我们一个分组丢失了。由于接收方只有在收到另一个报文段时才会产生重复的 ACK，而该报文段已经离开了
网络并进入了接收方的缓存。也就是说，在收发两端之间仍然有流动的数据，而我们不想执行慢启动来突然减少数据流。

这个算法通常按如下过程进行实现：

1. 当收到第 3 个重复的 ACK 时，将 ssthresh 设置为当前拥塞窗口 cwnd 的一半。重传丢失的报文段。设置 cwnd 为 ssthresh 加上 3 倍的报文段大小。
2. 每次收到另一个重复的 ACK 时，cwnd 增加 1 个报文段大小并发送 1 个分组（如果新的 cwnd 允许发送）。
3. 当下一个确认新数据的 ACK 到达时，设置 cwnd 为 ssthresh（在第 1 步中设置的值）。这个ACK 应该是在进行重传后的一个往返时间内对步骤 1 中重传的确认。另外，这个 ACK 也应该是对丢失的分组和收到的第 1 个重复的 ACK 之间的所有中间报文段的确认。这一步采用的是拥塞避免，因为当分组丢失时我们将当前的速率减半。

## 名词英文解释

> 方便理解名称的含义

- additive-increase 加性增长
- multiplicative-decrease 线性减少
- congestion window (cwnd)
- advertised window (rwnd)
- the slow start threshold (ssthresh)

Another state variable, the slow start threshold (`ssthresh`), is usedto determine whether the slow start or congestion avoidance algorithmis used to control data transmission,

The slow start algorithm is used when `cwnd` < `ssthresh`, while thecongestion avoidance algorithm is used when `cwnd` > `ssthresh`. Whencwnd and `ssthresh` are equal, the sender may use either slow start orcongestion avoidance.

## Links

- [TCP 拥塞控制算法](https://zhuanlan.zhihu.com/p/59656144)
- [(RFC) TCP Congestion Control](https://datatracker.ietf.org/doc/html/rfc5681)
- [超时重传机制](https://www.cnblogs.com/-wenli/p/13080675.html)
- [图解 TCP 重传、滑动窗口、流量控制、拥塞控制](https://www.cnblogs.com/xiaolincoding/p/12732052.html)
