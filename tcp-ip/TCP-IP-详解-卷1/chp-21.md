# TCP的超时与重传

- RTT
- RTO
- 拥塞避免算法 (congestion avoidance)
- 快速重传与快速恢复算法 (fast retransmit,fast recovery)
- 慢启动 (slow start)

网络出现拥塞的时候发生了什么？

- additive-increase
- multiplicative-decrease
- congestion window (cwnd)
- advertised window (rwnd)
- the slow start threshold (ssthresh)

Another state variable, the slow start threshold (ssthresh), is used
to determine whether the slow start or congestion avoidance algorithm
is used to control data transmission,

 The slow start algorithm is used when cwnd < ssthresh, while the
   congestion avoidance algorithm is used when cwnd > ssthresh.  When
   cwnd and ssthresh are equal, the sender may use either slow start or
   congestion avoidance.

## Links

- [https://zhuanlan.zhihu.com/p/59656144](https://zhuanlan.zhihu.com/p/59656144)
- [（RFC）TCP Congestion Control](https://datatracker.ietf.org/doc/html/rfc5681)
- [超时重传机制](https://www.cnblogs.com/-wenli/p/13080675.html)
- [图解 TCP 重传、滑动窗口、流量控制、拥塞控制](https://www.cnblogs.com/xiaolincoding/p/12732052.html)