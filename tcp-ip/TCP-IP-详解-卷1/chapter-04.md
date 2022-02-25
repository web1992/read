# ARP：地址解析协议

核心：数据在网络中的链路层传输的时候，需要以太网地址（硬件地址）。

> 名词：

- ARP（地址解析协议）和 RARP（逆地址解析协议）

本章我们要讨论的问题是只对 TCP/IP 协议簇有意义的 IP 地址。数据链路如以太网或令牌环网都有自己的寻址机制（常常为 48 bit 地址），这是使用数据链路的任何网络层都必须遵从的。

当一台主机把以太网数据帧发送到位于同一局域网上的另一台主机时，是根据 48 bit 的以太网地址来确定目的接口的。设备驱动程序从不检查 IP 数据报中的目的 IP 地址。

地址解析为这两种不同的地址形式提供映射：`32bit的IP地址`和数据`链路层`使用的任何类型的`地址`。RFC826[Plummer 1982]是 ARP 规范描述文档。

ARP 为`IP地址`到对应的`硬件地址`之间提供动态映射

> 32 IP 地址与 48 位以太网地址的转化（通过 ARP 和 RARP ）

![TCP-IP-4-1.png](./images/TCP-IP-4-1.drawio.svg)

```log
[root@aliyun1 ~]# arp -a
? (10.0.9.2) at 02:42:0a:00:09:02 [ether] on docker0
? (10.0.15.0) at a6:d1:ea:4e:72:6f [ether] PERM on flannel.1
? (10.0.9.4) at 02:42:0a:00:09:04 [ether] on docker0
? (169.254.169.254) at <incomplete> on eth0
? (10.0.9.6) at 02:42:0a:00:09:06 [ether] on docker0
? (10.0.10.0) at da:06:4e:48:0b:9b [ether] PERM on flannel.1
gateway (172.19.175.253) at ee:ff:ff:ff:ff:ff [ether] on eth0
? (10.0.9.3) at 02:42:0a:00:09:03 [ether] on docker0
? (10.0.9.5) at 02:42:0a:00:09:05 [ether] on docker0
```

## ARP 协议格式

ARP 发送一份称作 ARP 请求的以太网数据帧给以太网上的每个主机。这个过程称作广播。ARP 请求数据帧中包含目的主机的 IP 地址。
其意思是`如果你是这个IP地址的拥有者，请回答你的硬件地址。`

> ARP 协议格式

![TCP-IP-4-3.png](./images/TCP-IP-4-3.drawio.svg)
