# 第8章 Linux设备驱动中的阻塞与非阻塞I/O

- P593
- 阻塞与非阻塞I/O
- 使用O_NONBLOCK标记打开文件
- O_RDWR
- ioctl 和 fcntl
- fcntl（fd，F_SETFL，O_NONBLOCK）
- Wait Queue
- wait_queue_head_t my_queue;
- select（）和poll（）
- epoll
- timeval
- 边缘触发（Edge Triggered）模式
- 水平触发（Level Triggered）
-https://www.kernel.org/doc/ols/2004/ols2004v1-pages-215-226.pdf
-
-
-
- 
-
-
-
-
-
-
- 
-
-
-
-
-
-
- 
-
-
-
-
-
-





## 阻塞与非阻塞I/O


阻塞操作是指在执行设备操作时，若不能获得资
源，则挂起进程直到满足可操作的条件后再进行操
作。被挂起的进程进入睡眠状态，被从调度器的运行
队列移走，直到等待的条件被满足。而非阻塞操作的
进程在不能进行设备操作时，并不挂起，它要么放
弃，要么不停地查询，直至可以进行操作为止。
驱动程序通常需要提供这样的能力：当应用程序
进行read（）、write（）等系统调用时，若设备的资
源不能获取，而用户又希望以阻塞的方式访问设备，
驱动程序应在设备驱动的xxx_read（）、
xxx_write（）等操作中将进程阻塞直到资源可以获
取，此后，应用程序的read（）、write（）等调用才
返回，整个过程仍然进行了正确的设备访问，用户并
没有感知到；若用户以非阻塞的方式访问设备文件，
则当设备资源不可获取时，设备驱动的
xxx_read（）、xxx_write（）等操作应立即返回，
read（）、write（）等系统调用也随即被返回，应用
程序收到-EAGAIN返回值。


## select

```c
int select(int numfds, fd_set *readfds, fd_set *writefds,
fd_set *exceptfds,
struct timeval *timeout);
```

其中readfds、writefds、exceptfds分别是被
select（）监视的读、写和异常处理的文件描述符集
合，numfds的值是需要检查的号码最高的fd加1。
readfds文件集中的任何一个文件变得可读，
select（）返回；同理，writefds文件集中的任何一
个文件变得可写，select也返回。


，第一次对n个文件进行select（）
的时候，若任何一个文件满足要求，select（）就直
接返回；第2次再进行select（）的时候，没有文件满
足读写要求，select（）的进程阻塞且睡眠。由于调
用select（）的时候，每个驱动的poll（）接口都会
被调用到，实际上执行select（）的进程被挂到了每
个驱动的等待队列上，可以被任何一个驱动唤醒。如
果FDn变得可读写，select（）返回。


![select-pool](images/select-pool.png)


## poll

poll（）的功能和实现原理与select（）相似，
其函数原型为：

```c
int poll(struct pollfd *fds, nfds_t nfds, int timeout);
```

当多路复用的文件数量庞大、I/O流量频繁的时
候，一般不太适合使用select（）和poll（），此种
情况下，select（）和poll（）的性能表现较差，我
们宜使用epoll。epoll的最大好处是不会随着fd的数
目增长而降低效率，select（）则会随着fd的数量增
大性能下降明显。

## epoll


```c
int epoll_create(int size);

int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);

```

https://www.kernel.org/doc/ols/2004/ols2004v1-
pages-215-226.pdf 的文档《Comparing and
Evaluating epoll，select，and poll Event
Mechanisms》对比了select、epoll、poll之间的一些
性能。一般来说，当涉及的fd数量较少的时候，使用
select是合适的；如果涉及的fd很多，如在大规模并
发的服务器中侦听许多socket的时候，则不太适合选
用select，而适合选用epoll。

阻塞与非阻塞访问是I/O操作的两种不同模式，前
者在暂时不可进行I/O操作时会让进程睡眠，后者则不
然。
在设备驱动中阻塞I/O一般基于等待队列或者基于
等待队列的其他Linux内核API来实现，等待队列可用
于同步驱动中事件发生的先后顺序。使用非阻塞I/O的
应用程序也可借助轮询函数来查询设备是否能立即被
访问，用户空间调用select（）、poll（）或者epoll
接口，设备驱动提供poll（）函数。设备驱动的
poll（）本身不会阻塞，但是与poll（）、
select（）和epoll相关的系统调用则会阻塞地等待至
少一个文件描述符集合可访问或超时。