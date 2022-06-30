# JVM 线程分析 

## 线程分析

```sh
ps -mp 41450 -o THREAD,tid,time

printf "%x\n" 41458
# a1f2

jstack 41450 |grep  -A 10 a1f2

```