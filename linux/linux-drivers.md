# drivers

内核一般要做到drivers与arch的软件架构分离，
驱动中不包含板级信息，让驱动跨平台。同时内核的
通用部分（如kernel、fs、ipc、net等）则与具体的
硬件（arch和drivers）剥离。

- task_struct
- pthread_create
- TASK_WAKEKILL|TASK_UNINTERRUPTIBLE
- kernel_thread
- MMU
- Buddy算法
- Kswapd（交换进程）
- per-BDI flusher线程
- （LRU）算法
- Android内核 Binder进程间通信方式
- UNIX域套接字
- obj-y
- obj-n
- obj-m
- Kconfig
- bootrom
- bootloader
- CPU0
- bootloader引导Linux内核
- init程序
- 内核zImage
- 内核dtb
- 用户空间的init程序常用的有busybox init、SysVinit、systemd
- __FUNCTION__
- __func__
- __attribute__
- GUN C支持noreturn、format、section、aligned、packed等十多个属性。

## Kconfig和Makefile

在Linux内核中增加程序需要完成以下3项工作。
·将编写的源代码复制到Linux内核源代码的相应
目录中。
·在目录的Kconfig文件中增加关于新源代码对应
项目的编译配置选项。
·在目录的Makefile文件中增加对新源代码的编
译条目。


## 目标定义

```makefile
obj-y += foo.o
```

表示要由foo.c或者foo.s文件编译得到foo.o并链
接进内核（无条件编译，所以不需要Kconfig配置选
项），而obj-m则表示该文件要作为模块编译。obj-n
形式的目标不会被编译。


## Linux内核的引导


引导Linux系统的过程包括很多阶段，这里将以引
导ARM Linux为例来进行讲解（见图3.11）。一般的
SoC内嵌入了bootrom，上电时bootrom运行。对于CPU0
而言，bootrom会去引导bootloader，而其他CPU则判
断自己是不是CPU0，进入WFI的状态等待CPU0来唤醒
它。CPU0引导bootloader，bootloader引导Linux内
核，在内核启动阶段，CPU0会发中断唤醒CPU1，之后
CPU0和CPU1都投入运行。CPU0导致用户空间的init程
序被调用，init程序再派生其他进程，派生出来的进
程再派生其他进程。CPU0和CPU1共担这些负载，进行
负载均衡。
