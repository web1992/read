# GC 工具

- jcmd <pid> VM.metaspace 
- jstat -gcutil <pid> 1s
- jstat -gc <pid> 1s
- jps -v
- jinfo <pid>
- java -XX:+PrintFlagsFinal 打印Java的默认参数

## jstat

某次服务内存被占用的日志，FGC 次数达到 20373次

```java
[admin@zb_1-2-3-4_lin ~]# /data/java/jdk1.8.0_45/bin/jstat -gcutil 11498
  S0     S1     E      O      M     CCS    YGC     YGCT    FGC    FGCT     GCT
  0.00   0.00 100.00 100.00  94.17  91.88    523   11.514 20373 29840.597 29852.112
```

## Links

- [jstat 分析GC+内存占用](https://www.cnblogs.com/StarbucksBoy/p/11342188.html)
- [jcmd](https://www.cnblogs.com/webor2006/p/10669472.html)
- [jvm 常用的命令](https://www.cnblogs.com/duanxz/p/6115722.html)