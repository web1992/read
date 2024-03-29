# TCP 的保活定时器

- 保活功能就是试图在服务器端检测到这种半开放的连接。

许多 TCP/IP 的初学者会很惊奇地发现可以没有任何数据流通过一个空闲的 TCP 连接。
也就是说，如果 TCP 连接的双方都没有向对方发送数据，则在两个 TCP 模块之间不交换任何信息。
例如，没有可以在其他网络协议中发现的轮询。这意味着我们可以启动一个客户与服务器建
立一个连接，然后离去数小时、数天、数个星期或者数月，而连接依然保持。中间路由器可
以崩溃和重启，电话线可以被挂断再连通，但是只要两端的主机没有被重启，则连接依然保持建立。

这意味着两个应用进程—客户进程或服务器进程—都没有使用应用级的定时器来检
测非活动状态，而这种非活动状态可以导致应用进程中的任何一个终止其活动。

然而，许多时候一个服务器希望知道客户主机是否崩溃并关机或者崩溃又重新启动。许
多实现提供的保活定时器可以提供这种能力。
保活并不是 TCP 规范中的一部分。HostRequirementsRFC 提供了 3 个不使用保活定
时器的理由：

1. 在出现短暂差错的情况下，这可能会使一个非常好的连接释放掉；
2. 它们耗费不必要的带宽；
3. 在按分组计费的情况下会在互联网上花掉更多的钱。

然而，许多实现提供了保活定时器。保活定时器是一个有争论的功能。许多人认为如果需要，这个功能不应该在 TCP 中提供，
而应该由应用程序来完成。这是应当认真对待的一些问题之一，因为在这个论题上有些人表达出了很大的热情。

在连接两个端系统的网络出现临时故障的时候，保活选项会引起一个实际上很好的连接
终止。例如，如果在一个中间路由器崩溃并重新启动时发送保活探查，那么 TCP 会认为客户
的主机已经崩溃，而实际上所发生的并非如此。

保活功能主要是为服务器应用程序提供的。服务器应用程序希望知道客户主机是否崩溃，
从而可以代表客户使用资源。
