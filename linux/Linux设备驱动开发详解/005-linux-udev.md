# 第5章 Linux文件系统与设备文件

- P350
- devfs
- udev
- 文件系统与设备驱动的关系。
- 文件操作系统调用
- int creat(const char *filename, mode_t mode); 
- int umask(int newmask)
- int open(const char *pathname, int flags);
- int open(const char *pathname, int flags, mode_t mode);
- 文件打开标志  O_RDONLY、O_WRONLY、O_RDWR三
- 文件访问权限 S_IRUSR、S_IWUSR、S_IXUSR
- open("test", O_CREAT, S_IRWXU | S_IROTH | S_IXOTH | S_ISUID);
- 文件描述符
- int read(int fd, const void *buf, size_t length);
- int write(int fd, const void *buf, size_t length);
- int open(pathname, O_CREAT | O_WRONLY | O_TRUNC, mode);
- int lseek(int fd, offset_t offset, int whence);
- lseek(fd, 0, SEEK_END);
- int close(int fd);
- C库文件操作
- fiLE *fopen(const char *path, const char *mode);
- VFS
- file和inode这两个结构体。
- register_chrdev
- unregister_chrdev
- udev取代devfs
- 机制和策略的分离
- （Hotplug Event）
- netlink套接字
- uevent
- sysfs文件系统
- bus_type、device_driver和 来描 个 device来描述总线、驱动和设备

## 设备驱动

驱动最终通过与文件操作相关的系统调用
或C库函数（本质也基于系统调用）被访问，而设备驱
动的结构最终也是为了迎合提供给应用程序员的API。


```c
1 #include <sys/types.h>
2 #include <sys/stat.h>
3 #include <fcntl.h>
4 #include <stdio.h>
5 #define LENGTH 100
6 main()
7 {
8 int fd, len;
9 char str[LENGTH];
10
11 fd = open("hello.txt", O_CREAT | O_RDWR, S_IRUSR |
S_IWUSR); /*
12 创建并打开文件
*/
13 if (fd) {
14 write(fd, "Hello World", strlen("Hello World"));
/*
15 写入字符串
*/
16 close(fd);
17 }
18
19 fd = open("hello.txt", O_RDWR);
20 len = read(fd, str, LENGTH); /* 读取文件内容
*/
21 str[len] = '\0';
22 printf("%s\n", str);
23 close(fd);
24 }
```

## C库文件操作

C库函数的文件操作实际上独立于具体的操作系统
平台，不管是在DOS、Windows、Linux还是在VxWorks
中都是这些函数：


```c
int fgetc(fiLE *stream);
int fputc(int c, fiLE *stream);
char *fgets(char *s, int n, fiLE *stream);
int fputs(const char *s, fiLE *stream);
int fprintf(fiLE *stream, const char *format, ...);
int fscanf (fiLE *stream, const char *format, ...);
size_t fread(void *ptr, size_t size, size_t n, fiLE *stream);
size_t fwrite (const void *ptr, size_t size, size_t n, fiLE *stream);
```


```c
1 #include <stdio.h>
2 #define LENGTH 100
3 main()
4 {
5 fiLE *fd;
6 char str[LENGTH];
7
8 fd = fopen("hello.txt", "w+");/* 创建并打开文件
*/
9 if (fd) {
10 fputs("Hello World", fd); /* 写入字符串
*/
11 fclose(fd);
12 }
13
14 fd = fopen("hello.txt", "r");
15 fgets(str, LENGTH, fd); /* 读取文件内容
*/
16 printf("%s\n", str);
17 fclose(fd);
18 }
```

## 文件结构体

```c
1 struct file {
2 union {
3 struct llist_node fu_llist;
4 struct rcu_head fu_rcuhead;
5 } f_u;
6 struct path f_path;
7 #define f_dentry f_path.dentry
8 struct inode *f_inode; /* cached value
*/
9 const struct file_operations*f_op; /* 和文件关联的操作
*/
10
11 /*
12 * Protects f_ep_links, f_flags.
13 * Must not be taken from IRQ context.
14 */
15 spinlock_t f_lock;
16 atomic_long_t f_count;
17 unsigned int f_flags;
 /*文件标志，如
O_RDONLY、
O_NONBLOCK、
O_SYNC*/
18 fmode_t f_mode; /*文件读
/写模式，
FMODE_READ和
FMODE_WRITE*/
19 struct mutex f_pos_lock;
20 loff_t f_pos; /* 当前读写位置
*/
21 struct fown_struct f_owner;
22 const struct cred *f_cred;
23 struct file_ra_statef_ra;
24
25 u64 f_version;
26 #ifdef CONfiG_SECURITY
27 void *f_security;
28 #endif
29 /* needed for tty driver, and maybe others */
30 void *private_data; /*文件私有数据
*/
31
32 #ifdef CONfiG_EPOLL
33 /* Used by fs/eventpoll.c to link all the hooks to this
file */
34 struct list_head f_ep_links;
35 struct list_head f_tfile_llink;
36 #endif /* #ifdef CONfiG_EPOLL
*/
37 struct address_space*f_mapping;
38 } __attribute__((aligned(4))); /* lest something
weird decides that 2 is OK */
```


## 机制和策略的分离

Linux设计中强
调的一个基本观点是机制和策略的分离。机制是做某
样事情的固定步骤、方法，而策略就是每一个步骤所
采取的不同方式。机制是相对固定的，而每个步骤采
用的策略是不固定的。机制是稳定的，而策略则是灵
活的，因此，在Linux内核中，不应该实现策略

## sysfs

sysfs的一个目的
就是展示设备驱动模型中各组件的层次关系，其顶级
目录包括block、bus、dev、devices、class、fs、
kernel、power和firmware等


device_driver和device分别表示驱动和设备，而这两者都必须
依附于一种总线，因此都包含struct bus_type指针。在Linux
内核中，设备和驱动是分开注册的，注册1个设备的时候，并不需要
驱动已经存在，而1个驱动被注册的时候，也不需要对应的设备已经
被注册。设备和驱动各自涌向内核，而每个设备和驱动涌入内核的
时候，都会去寻找自己的另一半，而正是bus_type的match（）成
员函数将两者捆绑在一起。简单地说，设备和驱动就是红尘中漂浮
的男女，而bus_type的match（）则是牵引红线的月老，它可以识
别什么设备与什么驱动是可配对的。一旦配对成功，xxx_driver
的probe（）就被执行（xxx是总线名，如platform、pci、i2c、spi、usb等）。