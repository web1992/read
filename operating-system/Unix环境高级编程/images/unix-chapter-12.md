# 第12章 高级I/O

- select 函数
- poll 函数
- 异步I/O

## select 

select函数使我们在SVR4和4.3+BSD之下可以执行I/O多路转接，传向select的参数告诉内核：
(1) 我们所关心的描述符。
(2) 对于每个描述符我们所关心的条件（是否读一个给定的描述符？是否想写一个给定的描述符？是否关心一个描述符的异常条件？）
(3) 希望等待多长时间（可以永远等待，等待一个固定量时间，或完全不等待）。从select返回时，内核告诉我们：
(1) 已准备好的描述符的数量。
(2) 哪一个描述符已准备好读、写或异常条件。
使用这种返回值，就可调用相应的I / O函数（一般是r e a d或w r i t e），并且确知该函数不会阻塞。

```c
#include <sys/types.h>/* fd_set data type */
#include <sys/time.h> /* struct timeval */
#include <unistd.h> /* function prototype might be here */
// 返回：准备就绪的描述符数，若超时则为0，若出错则为- 1
int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *tvptr);
struct timeval{
    long tv_sec; /* seconds */
    long tv_usec; /* and microseconds */
};

```

有三种情况：

- tvptr==NULL

永远等待。如果捕捉到一个信号则中断此无限期等待。当所指定的描述符中的一个已准备好或捕捉到一个信号则返回。如果捕捉到一个信号，则select返回－1，errno设置为EINTR。

- tvptr->tv_sec==0&&tvptr->tv_usec==0

完全不等待。测试所有指定的描述符并立即返回。这是得到多个描述符的状态而不阻塞select函数的轮询方法。

- tvptr->tv_sec!=0||tvptr->tv_usec!=0

等待指定的秒数和微秒数。

当指定的描述符之一已准备好，或当指定的时间值已经超过时立即返回。如果在超时时还没有一个描述符准备好，则返回值是0，（如果系统不提供微秒分辨率，则tvptr->tv_usec值取整到最近的支持值。）
与第一种情况一样，这种等待可被捕捉到的信号中断。中间三个参数readfds、writefds和exceptfds是指向描述符集的指针。
这三个描述符集说明了我们关心的可读、可写或处于异常条件的各个描述符。每个描述符集存放在一个fdset数据类型中。这种数据类型的实现可见图12-9，它为每一可能的描述符保持了一位。
