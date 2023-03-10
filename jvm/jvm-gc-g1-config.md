# G1 配置

RocketMQ 的G1参数配置

```config
-Xms1g
-Xmx1g
-XX:+UseG1GC
-XX:G1HeapRegionSize=16m
-XX:G1ReservePercent=25
-XX:InitiatingHeapOccupancyPercent=30
-XX:SoftRefLRUPolicyMSPerMB=0
-verbose:gc
-Xloggc:/dev/shm/rmq_broker_gc_%p_%t.log
-XX:+PrintGCDetails
-XX:+PrintGCDateStamps
-XX:+PrintGCApplicationStoppedTime
-XX:+PrintAdaptiveSizePolicy
-XX:+UseGCLogFileRotation
-XX:NumberOfGCLogFiles=5
-XX:GCLogFileSize=30m
-XX:-OmitStackTraceInFastThrow
-XX:+AlwaysPreTouch
-XX:MaxDirectMemorySize=15g
-XX:-UseLargePages
-XX:-UseBiasedLocking
```

- -Xms1g 启动时占用内存
- -Xmx1g 最大可占用的内存大小
- -XX:+UseG1GC 开启G1
- -XX:G1HeapRegionSize=16m 设置G1每个region的大小，2的倍数，1MB to 32MB（默认总共）
- -XX:G1ReservePercent=25  G1会保留一部分堆内存用来防止分配不了的情况，默认是10
- -XX:InitiatingHeapOccupancyPercent=30 全部使用的region占到总堆空间多少开始gc，默认值45%。调小可以早点开始gc周期
- -XX:SoftRefLRUPolicyMSPerMB=0
- -verbose:gc
- -Xloggc:/dev/shm/rmq_broker_gc_%p_%t.log
- -XX:+PrintGCDetails
- -XX:+PrintGCDateStamps 输出时间戳：2022-03-11T10:59:50.550+0800:
- -XX:+PrintGCApplicationStoppedTime 打印应用由于GC而产生的停顿时间
- -XX:+PrintAdaptiveSizePolicy
- -XX:+UseGCLogFileRotation 设置GC日志滚动存储,需要个下面的NumberOfGCLogFiles,GCLogFileSize配合使用
- -XX:NumberOfGCLogFiles=5
- -XX:GCLogFileSize=30m GC GC日志文件大小
- -XX:-OmitStackTraceInFastThrow
- -XX:+AlwaysPreTouch 开启物理内存的预分配，会减慢JVM启动时间，但是会加快响应时间
- -XX:MaxDirectMemorySize=15g 设置 direct ByteBuffer 堆外内存的大小
- -XX:-UseLargePages 关闭大页
- -XX:-UseBiasedLocking 关闭偏向锁


```config
# G1 GC总结-参数说明
-XX:MaxGCPauseMillis: 期望最大暂停时间，默认值200ms
-XX:G1HeapRegionSize: Region大小，若未指定则默认最多生成2048块
-XX:G1NewSizePercent/G1MaxNewSizePercert: 新生代比例有两个数值指定，下限默认值5%，上限默认值60%
-XX:ConcGCThreads: 指定并发GC线程数: (3 + ParallelGCThreads) / 4 
-XX:ParallelGCThreads: 指定并行GC线程数，STW阶段GC线程数: CPU核心数*5/8 + 3
-XX:G1MixedGCLiveThresholdPercent: 指定被纳入CSet的Region 占比，默认值85%
-XX:lnitiatingHeapOccupancyPercent: 指定触发全局并发标记的老年代占比，默认值45%
-XX:G1HeapWastePercent: 指定触发Mixed GC的堆垃圾占比，默认值5%
-XX:G1OIdCSetRegionThresholdPercent: 指定每轮Mixed GC回收的Region最大比例，默认10% 
-XX:G1MixedGCCountTarget: 指定一个周期内触发Mixed GC最大次数，默认值8
-XX:G1ReservePercent: 指定G1为分配担保预留的空间比例，默认10%
```

## Links

- [https://www.oracle.com/technical-resources/articles/java/g1gc.html](https://www.oracle.com/technical-resources/articles/java/g1gc.html)
- [GC 日志解读](https://blog.csdn.net/qq_33229669/article/details/106035861)
- [https://www.oracle.com/java/technologies/javase/vmoptions-jsp.html](https://www.oracle.com/java/technologies/javase/vmoptions-jsp.html)
- [避免栈异常信息丢失 -OmitStackTraceInFastThrow](https://blog.csdn.net/zshake/article/details/88796414)
- [+AlwaysPreTouch](https://www.jianshu.com/p/a8356d03ac8f)
- [+MaxDirectMemorySize](https://www.cnblogs.com/laoqing/p/10380536.html)
- [TLB和内存大页(UseLargePages)](https://blog.csdn.net/zero__007/article/details/52926366)