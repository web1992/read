# IP选路

- netstat -rn 查询路由信息
- ifconfig 更新路由表
- route 命令
- 差错报文
- ICMP重定向差错
- ICMP路由器发现报文

```log
[root@xxx ~]# netstat -rn
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         154.211.13.1    0.0.0.0         UG        0 0          0 eth0
154.211.13.0    0.0.0.0         255.255.255.0   U         0 0          0 eth0
169.254.0.0     0.0.0.0         255.255.0.0     U         0 0          0 eth0
```

对于一个给定的路由器，可以打印出五种不同的标志（flag）：

U 该路由可以使用。
G 该路由是到一个网关（路由器）。如果没有设置该标志，说明目的地是直接相连的。
H 该路由是到一个主机，也就是说，目的地址是一个完整的主机地址。如果没有设置该
标志，说明该路由是到一个网络，而目的地址是一个网络地址：一个网络号，或者网络号与子网号的组合。
D 该路由是由重定向报文创建的
M 该路由已被重定向报文修改

标志G是非常重要的，因为由它区分了间接路由和直接路由（对于直接路由来说是不设置
标志G的）。其区别在于，发往直接路由的分组中不但具有指明目的端的IP地址，还具有其链
路层地址（见图3-3）。当分组被发往一个间接路由时，IP地址指明的是最终的目的地，但是
链路层地址指明的是网关（即下一站路由器

> 初始化路由表

我们从来没有说过这些路由表是如何被创建的。每当初始化一个接口时（通常是用
ifconfig命令设置接口地址），就为接口自动创建一个直接路由。对于点对点链路和环回接口
来说，路由是到达主机（例如，设置H标志）。对于广播接口来说，如以太网，路由是到达网络。

> 差错报文

当路由器收到一份I P数据报但又不能转发时，就要发送一份ICMP*主机不可达*差错报文

IP路由操作对于运行TCP／IP的系统来说是最基本的，不管是主机还是路由器。路由表项
的内容很简单，包括：5bit标志、目的IP地址（主机、网络或默认）、下一站路由器的IP地址
（间接路由）或者本地接口的IP地址（直接路由）及指向本地接口的指针。主机表项比网络表
项具有更高的优先级，而网络表项比默认项具有更高的优先级。
系统产生的或转发的每份IP数据报都要搜索路由表，它可以被路由守护程序或ICMP重定
向报文修改。系统在默认情况下不转发数据报，除非进行特殊的配置。用route命令可以进
入静态路由，可以利用新ICMP路由器发现报文来初始化默认表项，并进行动态修改。主机在
启动时只有一个简单的路由表，它可以被来自默认路由器的ICMP重定向报文动态修改。
