# 第14章 Linux网络设备驱动

- P1055
- Linux网络设备驱动的结构
- dev_queue_xmit
- 网络协议接口层
- int dev_queue_xmit(struct sk_buff *skb);
- netif_rx
- int netif_rx(struct sk_buff *skb);
- 套接字缓冲区 sk_buff
- skbuff.h
- alloc_skb
- dev_alloc_skb
- void kfree_skb(struct sk_buff *skb);
- void dev_kfree_skb(struct sk_buff *skb);
- void dev_kfree_skb_irq(struct sk_buff *skb);
- void dev_kfree_skb_any(struct sk_buff *skb);
- *skb_put
- skb_reserve
- net_device结构体
- base_addr为网络设备I/O基地址。
- irq为设备使用的中断号。
- if_port指定多端口设备使用哪一个端口，该字段仅针对多端口设备
- ETH_HLEN
- IFF _Interface Flags
- netdevice.h
- netdev_ops ethtool_ops、header_ops
- poll_controller
- NAPI（New API）
- register_netdev（）和 unregister_netdev（）
- net_device
- alloc_netdev_mqs  
- free_netdev alloc_enetdev
- request_region
- 网络设备的打开与释放
- netif_start_queue（）和 netif_stop_queue（）
- netif_receive_skb
- 网络连接状态
- netif_carrier_on（）和 netif_carrier_off（）
- netif_carrier_ok
- 载波信号
- 参数设置和统计数据
- netif_running
- SIOCSIFMAP ioctl
- DM9000网卡设备驱动实例
- DM9000一般直接挂在外面的内存总线上 可以和CPU直连
- 
- 

## 网络设备

网络设备是完成用户数据包在网络媒介上发送和
接收的设备，它将上层协议传递下来的数据包以特定
的媒介访问控制方式进行发送，并将接收到的数据包
传递给上层协议。
与字符设备和块设备不同，网络设备并不对应
于/dev目录下的文件，应用程序最终使用套接字完成
与网络设备的接口。因而在网络设备身上并不能体现
出“一切都是文件”的思想。
Linux系统对网络设备驱动定义了4个层次，这4个
层次为网络协议接口层、网络设备接口层、提供实际
功能的设备驱动功能层和网络设备与媒介层。

## Linux网络设备驱动的结构

![net device layer](images/014-linux-net-device-layer.png)

Linux网络设备驱动程序的体系结构如图14.1所
示，从上到下可以划分为4层，依次为网络协议接口
层、网络设备接口层、提供实际功能的设备驱动功能
层以及网络设备与媒介层，这4层的作用如下所示。

1）网络协议接口层向网络层协议提供统一的数据
包收发接口，不论上层协议是ARP，还是IP，都通过
dev_queue_xmit（）函数发送数据，并通过
netif_rx（）函数接收数据。这一层的存在使得上层
协议独立于具体的设备。

2）网络设备接口层向协议接口层提供统一的用于
描述具体网络设备属性和操作的结构体net_device，
该结构体是设备驱动功能层中各函数的容器。实际
上，网络设备接口层从宏观上规划了具体操作硬件的
设备驱动功能层的结构。

3）设备驱动功能层的各函数是网络设备接口层
net_device数据结构的具体成员，是驱使网络设备硬
件完成相应动作的程序，它通过hard_start_xmit（）
函数启动发送操作，并通过网络设备上的中断触发接
收操作。

4）网络设备与媒介层是完成数据包发送和接收的
物理实体，包括网络适配器和具体的传输媒介，网络
适配器被设备驱动功能层中的函数在物理上驱动。对
于Linux系统而言，网络设备和媒介都可以是虚拟的。

在设计具体的网络设备驱动程序时，我们需要完
成的主要工作是编写设备驱动功能层的相关函数以填
充net_device数据结构的内容并将net_device注册入
内核。

## sk_buff结构体

sk_buff结构体非常重要，它定义于
include/linux/skbuff.h文件中，含义为“套接字缓
冲区”，用于在Linux网络子系统中的各层之间传递数
据，是Linux网络子系统数据传递的“中枢神经”。

当发送数据包时，Linux内核的网络处理模块必须
建立一个包含要传输的数据包的sk_buff，然后将
sk_buff递交给下层，各层在sk_buff中添加不同的协
议头直至交给网络设备发送。同样地，当网络设备从
网络媒介上接收到数据包后，它必须将接收到的数据
转换为sk_buff数据结构并传递给上层，各层剥去相应
的协议头直至交给用户。

尤其值得注意的是head和end指向
缓冲区的头部和尾部，而data和tail指向实际数据的
头部和尾部。每一层会在head和data之间填充协议
头，或者在tail和end之间添加新的协议数据。


- [sk_buff结构体 资料来自cnblogs](https://www.cnblogs.com/ink-white/p/16814624.html)

![sk buff](images/014-linux-net-sk-buff.png)


```c
skb=alloc_skb(len+headspace, GFP_KERNEL);
skb_reserve(skb, headspace);
skb_put(skb,len);
memcpy_fromfs(skb->data,data,len);
pass_to_m_protocol(skb);
```

## net_device


net_device结构体的分配和网络设备驱动的注册
需在网络设备驱动程序初始化时进行，而net_device
结构体的释放和网络设备驱动的注销在设备或驱动被
移除的时候执行，

## 网络设备的打开与释放

网络设备的打开函数需要完成如下工作。
·使能设备使用的硬件资源，申请I/O区域、中断
和DMA通道等。
·调用Linux内核提供的netif_start_queue（）
函数，激活设备发送队列。
网络设备的关闭函数需要完成如下工作。
·调用Linux内核提供的netif_stop_queue（）函
数，停止设备传输包。
·释放设备所使用的I/O区域、中断和DMA资源。

## 数据发送流程

1）网络设备驱动程序从上层协议传递过来的
sk_buff参数获得数据包的有效数据和长度，将有效数
据放入临时缓冲区。

2）对于以太网，如果有效数据的长度小于以太网
冲突检测所要求数据帧的最小长度ETH_ZLEN，则给临
时缓冲区的末尾填充0。

3）设置硬件的寄存器，驱使网络设备进行数据发
送操作。

netif_wake_queue（）和
netif_stop_queue（）是数据发送流程中要调用的两
个非常重要的函数，分别用于唤醒和阻止上层向下传
送数据包，它们的原型定义于
include/linux/netdevice.h中

```c
static inline void netif_wake_queue(struct net_device *dev);
static inline void netif_stop_queue(struct net_device *dev);
```

## 数据接收流程

网络设备接收数据的主要方法是由中断引发设备
的中断处理函数，中断处理函数判断中断类型，如果
为接收中断，则读取接收到的数据，分配sk_buffer数
据结构和数据缓冲区，将接收到的数据复制到数据缓
冲区，并调用netif_rx（）函数将sk_buffer传递给上
层协议。代码清单14.9所示为完成这个过程的函数模板。

如果是NAPI兼容的设备驱动，则可以通过poll方
式接收数据包。在这种情况下，我们需要为该设备驱
动提供作为netif_napi_add（）参数的xxx_poll（）

## 总结

对Linux网络设备驱动体系结构的层次化设计实现
了对上层协议接口的统一和硬件驱动对下层多样化硬
件设备的可适应。程序员需要完成的工作集中在设备
驱动功能层，网络设备接口层net_device结构体的存
在将千变万化的网络设备进行抽象，使得设备功能层
中除数据包接收以外的主体工作都由填充net_device
的属性和函数指针完成。

在分析net_device数据结构的基础上，本章给出
了设备驱动功能层设备初始化、数据包收发、打开和
释放等函数的设计模板，这些模板对实际设备驱动的
开发具有直接指导意义。有了这些模板，我们在设计
具体设备的驱动时，不再需要关心程序的体系，而可
以将精力集中于硬件操作本身。


在Linux网络子系统和设备驱动中，套接字缓冲区
sk_buff发挥着巨大的作用，它是所有数据流动的载
体。网络设备驱动和上层协议之间也基于此结构进行
数据包交互，因此，我们要特别牢记它的操作方法。