# 套接字选项

关键字：

- fcntl
- ioctl

有很多方法来获取和设置影响套接字的选项

- getsockopt 和 setsockopt 函数;
- fcntl 函数;
- ioctl 函数;

fcntl 函数提供了与网络编程相关的如下特性。

非阻塞式 IO。通过使用 F_SETFL 命令设置 O_NONBLOCK 文件状态标志,我们可以把一个
套接字设置为非阻塞型。(参考 16 章)

信号驱动式 I/O，通过使用 F_SETFL 命令设置 O_ASYNC 文件状态标志,我们可以把一个套
接字设置成一旦其状态发生变化,内核就产生一个 SIGIO 信号。(参考 25 章)

F_SETOWN 命令允许我们指定用于接收 SIGIO 和 SIGURG 信号的套接字属主(进程 I 或进
程组 ID)。其中 SIGIO 信号是套接字被设置为信号驱动式 IO 型后产生的(第 25 章),
SIGURG 信号是在新的带外数据到达套接字时产生的(第 24 章)。F_GETOWN 命令返回套接字的当前属主。

```txt
术语“套接宇属主”由 POSIX 定义。历史上源自 Berkeley 的实现称之为“套接字的进程组
ID”,因为存放该 ID 的变量是 socket 结构的 so_pgid 成员(TCPV2 第 438 页)
```

使用 socket 函数新创建的套接字并没有属主。然而如果一个新的套接字是从一个监听套接
字创建来的,那么套接字属主将由已连接套接字从监听套接字继承而来(许多套接字选项也是
这样继承,见 TCPV2 第 462~463 页)。

> 图 7-20 fcntl、ioctl 和路由套接字操作小结

| 操作                           | fcntl               | ioctl                  | 路由套接字 | POSIX      |
| ------------------------------ | ------------------- | ---------------------- | ---------- | ---------- |
| 设置套接字为非阻寒式 IO 型     | F_SETFL, O_NONBLOCK | FIONBIO                |            | fcntl      |
| 设置套接字为信号驱动式 O 型    | F_SETFL, O_ASYNC    | FTOASYNC               |            | fcntl      |
| 设置套接字属主                 | F_SETON             | SIOCSPGRP 或 FTOSETOWI |            | fcntl      |
| 获取套接字属主                 | F_GETOWN            | SIOCGPGRP 或 FIOGETOWN |            | fcntl      |
| 获取套接字接收缓冲区中的字节数 |                     | FIONREAD               |            |            |
| 测试套接字是否处于带外标志     |                     | TSIOCATMARK            |            | sockatmark |
| 获取接口列表                   |                     | SIOCGIFCONF            | sysctl     |            |
| 接口操作                       |                     | SIOC[GS]IFxxx          |            |            |
| ARP 高速缓存操作               |                     | SIOCxxxARP             | RMT_xxx    |            |
| 路由表操作                     |                     | SIOCxxxRT              | RMT_xxx    |            |

## 套接字状态

对于某些套接字选项,针对套接字的状态,什么时候设置或获取选项有时序上的考虑。我们对受影响的选项论及这一点。

下面的套接字选项是由 TCP 已连接套接字从监听套接字`继承`来的(TCP2 第 462~463 页)
SO_DEBUG、 SO_DONTROUTE、 SO_KEEPALIVE、 SO_LINGER、 SO_OOBINLINE、 SO_RCVBUE、
SO_RCVLOWAT、 SO_SNDBUF、SO_SNDLOWAT、 TCP_MAXSEG 和 CP_NODELAY。

这对 TCP 是很重要的,因为 accept 一直要到 TCP 层完成三路握手后才会给服务器返回已连接套接字。
如果想在三路握手完成时确保这些套接字选项中的某一个是给`已连接套接字`设置的,那么我们必须先给`监听套接字`设置该选项。

> 注意：监听套接字的选项设置可以继承
