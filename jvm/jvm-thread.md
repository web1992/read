# JVM 线程分析 

## 线程分析

```sh
ps -mp 41450 -o THREAD,tid,time

printf "%x\n" 41458
# a1f2

jstack 41450 |grep  -A 10 a1f2

```


## Links

- [hotspot JVM 线程的创建，从虚拟机的角度看](https://juejin.cn/post/7054063538624528398)
- [内存对象分析](https://heaphero.io/heap-index.jsp)
