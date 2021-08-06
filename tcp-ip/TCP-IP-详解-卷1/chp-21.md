# TCP的超时与重传

TCP提供可靠的运输层。它使用的方法之一就是确认从另一端收到的数据。但数据和确
认都有可能会丢失。TCP通过在发送时设置一个定时器来解决这种问题。如果当定时器溢出
时还没有收到确认，它就重传该数据。对任何实现而言，关键之处就在于超时和重传的策略，
即怎样决定超时间隔和如何确定重传的频率。

我们已经看到过两个超时和重传的例子：（1）在6.5节的ICMP端口不能到达的例子中，看
到TFTP客户使用UDP实现了一个简单的超时和重传机制：假定5秒是一个适当的时间间隔，
并每隔5秒进行重传；（2）在向一个不存在的主机发送ARP的例子中（第4.5节），我们看到
当TCP试图建立连接的时候，在每个重传之间使用一个较长的时延来重传SYN。
对每个连接，TCP管理4个不同的定时器。

1)重传定时器使用于当希望收到另一端的确认。在本章我们将详细讨论这个定时器以及
一些相关的问题，如拥塞避免。
2)坚持(persist)定时器使窗口大小信息保持不断流动，即使另一端关闭了其接收窗口。第
22章将讨论这个问题。
3)保活(keepalive)定时器可检测到一个空闲连接的另一端何时崩溃或重启。第23章将描述
这个定时器。
4)2MSL定时器测量一个连接处于TIMEWAIT状态的时间。我们在18.6节对该状态进行
了介绍。

- RTT
- RTO
- 指数退避(exponential backoff)
- 拥塞避免算法 (congestion avoidance)
- 快速重传与快速恢复算法 (fast retransmit,fast recovery)
- 慢启动 (slow start)

网络出现拥塞的时候发生了什么？

- additive-increase
- multiplicative-decrease
- congestion window (cwnd)
- advertised window (rwnd)
- the slow start threshold (ssthresh)

Another state variable, the slow start threshold (`ssthresh`), is used
to determine whether the slow start or congestion avoidance algorithm
is used to control data transmission,

The slow start algorithm is used when `cwnd` < `ssthresh`, while the
congestion avoidance algorithm is used when `cwnd` > `ssthresh`.  When
cwnd and `ssthresh` are equal, the sender may use either slow start or
congestion avoidance.

## Links

- [TCP 拥塞控制算法](https://zhuanlan.zhihu.com/p/59656144)
- [(RFC) TCP Congestion Control](https://datatracker.ietf.org/doc/html/rfc5681)
- [超时重传机制](https://www.cnblogs.com/-wenli/p/13080675.html)
- [图解 TCP 重传、滑动窗口、流量控制、拥塞控制](https://www.cnblogs.com/xiaolincoding/p/12732052.html)
