# JVM 线程分析 

## 线程分析

```sh
top -H -p 6522

# or
ps -mp 13718 -o THREAD,tid,time

printf "%x\n" 6526 #795e
printf "%x\n" 6529 #795f
# 795f

jstack -F -l 13718 |grep  -A 10 a1f2

jstack -F -l 6522 > 6522.thread.txt

```


## Links

- [hotspot JVM 线程的创建，从虚拟机的角度看](https://juejin.cn/post/7054063538624528398)
- [内存对象分析](https://heaphero.io/heap-index.jsp)
- [Arthas分析内存](https://blog.csdn.net/qq_45443475/article/details/127305299)
