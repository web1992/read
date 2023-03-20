# GC 日志

> 基本格式

![jvm-gc-log-2023-01-11.drawio.svg](./images/jvm-gc-log-2023-01-11.drawio.svg)

> GC 日志的配置

```java
-Xloggc:/data/applogs/gc_%p_%t.log
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/data/dumplogs
-XX:+PrintGCDetails
-XX:+PrintGCDateStamps 
```

## 例子1

`JVM`参数配置

```java
Java HotSpot(TM) 64-Bit Server VM (25.45-b02) for linux-amd64 JRE (1.8.0_45-b14), built on Apr 10 2015 10:07:45 by "java_re" with gcc 4.3.0 20080428 (Red Hat 4.3.0-8)
Memory: 4k page, physical 7911456k(725848k free), swap 0k(0k free)
CommandLine flags: -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/gclogs/ -XX:InitialHeapSize=4294967296 -XX:+ManagementServer -XX:MaxHeapSize=4294967296 -XX:MaxMetaspaceSize=536870912 -XX:MetaspaceSize=268435456 -XX:+PrintGC -XX:+PrintGCDateStamps -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:+UseParallelGC
```

`JVM`的GC日志

```java
2023-03-02T09:34:00.393+0800: 45619.736: [GC (Allocation Failure) [PSYoungGen: 1379201K->15073K(1380352K)] 2072496K->712011K(4176896K), 0.0253115 secs] [Times: user=0.05 sys=0.00, real=0.02 secs]
```

每行是一次GC的信息，以本条为例，解读如下。
45619.736是本次GC发生的时间，从jvm启动起开始计时，单位为秒。

GC表示这是一次Minor GC（新生代垃圾收集）。

`PSYoungGen: 1379201K->15073K(1380352K)`。格式为`[PSYoungGen: a->b(c)]`.
PSYoungGen，表示新生代使用的是多线程垃圾收集器Parallel Scavenge。a为GC前新生代已占用空间，b为GC后新生代已占用空间。新生代又细分为一个Eden区和两个Survivor区,Minor GC之后Eden区为空，b就是Survivor中已被占用的空间。括号里的c表示整个年轻代的大小。

`2072496K->712011K(4176896K)`，格式为`x->y(z)`。x表示GC前堆的已占用空间，y表示GC后堆已占用空间，z表示堆的总大小。
由新生代和Java堆占用大小可以算出年老代占用空间，此例中就是`4176896K-1380352K=2796544`。

0.0253115 secs表示本次GC所消耗的时间。

`[Times: user=0.05 sys=0.00, real=0.02 secs]` 提供cpu使用及时间消耗，user是用户态消耗的cpu时间，sys是系统态消耗的cpu时间,real是实际的消耗时间。


## 优化配置

```
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/applogs -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/data/applogs/gc_%p_%t.log
```