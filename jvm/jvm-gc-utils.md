# GC 工具

- jcmd <pid> VM.metaspace 
- jstat -gcutil <pid> 1s
- jstat -gc <pid> 1s
- jps -v
- jinfo <pid>
- java -XX:+PrintFlagsFinal 打印Java的默认参数

## jstat

某次服务内存被占用的日志，FGC 次数达到 20373次，E和O的使用内存全部100%

```java
[admin@zb_1-2-3-4_lin ~]# /data/java/jdk1.8.0_45/bin/jstat -gcutil 11498
  S0     S1     E      O      M     CCS    YGC     YGCT    FGC    FGCT     GCT
  0.00   0.00 100.00 100.00  94.17  91.88    523   11.514 20373 29840.597 29852.112
```

```java
[admin@zb_1-2-3-34_lin ~]# /data/java/jdk1.8.0_45/bin/jstat -gc 11498
 S0C    S1C    S0U    S1U      EC       EU        OC         OU       MC     MU    CCSC   CCSU   YGC     YGCT    FGC    FGCT     GCT
43520.0 44544.0  0.0    0.0   214016.0 214015.7  647168.0   646955.0  75736.0 71111.4 9216.0 8471.0    523   11.514 20518 30036.109 30047.623
```

```java
"VM Thread" os_prio=0 tid=0x00007f71c80f9000 nid=0x2cee runnable

"GC task thread#0 (ParallelGC)" os_prio=0 tid=0x00007f71c801d800 nid=0x2cec runnable

"GC task thread#1 (ParallelGC)" os_prio=0 tid=0x00007f71c801f800 nid=0x2ced runnable

"VM Periodic Task Thread" os_prio=0 tid=0x00007f71c8142000 nid=0x2cf5 waiting on condition

JNI global references: 2134

Heap
 PSYoungGen      total 258560K, used 213788K [0x00000000ec400000, 0x00000000fff80000, 0x0000000100000000)
  eden space 214016K, 99% used [0x00000000ec400000,0x00000000f94c8cc8,0x00000000f9500000)
  from space 44544K, 0% used [0x00000000f9500000,0x00000000f9500000,0x00000000fc080000)
  to   space 43520K, 0% used [0x00000000fd500000,0x00000000fd500000,0x00000000fff80000)
 ParOldGen       total 647168K, used 646956K [0x00000000c4c00000, 0x00000000ec400000, 0x00000000ec400000)
  object space 647168K, 99% used [0x00000000c4c00000,0x00000000ec3cb160,0x00000000ec400000)
 Metaspace       used 71084K, capacity 75430K, committed 75480K, reserved 1116160K
  class space    used 8467K, capacity 9189K, committed 9216K, reserved 1048576K
```


``java
/data/java/jdk1.8.0_45/bin/jcmd 26106 GC.class_histogram

26106:

 num     #instances         #bytes  class name
----------------------------------------------
   1:       2887273      254080024  java.lang.reflect.Method
   2:       3523705      225517120  java.util.concurrent.ConcurrentHashMap
   3:       1388400      192156096  [C
   4:       4666576      149330432  java.util.HashMap$Node
   5:       2872391      114895640  org.apache.dubbo.rpc.model.ConsumerMethodModel
   6:        973566       65138040  [Ljava.util.HashMap$Node;
   7:       2883884       62924680  [Ljava.lang.Class;
   8:       2875465       62822584  [Ljava.lang.String;
   9:        965293       46334064  java.util.HashMap
  10:       1387894       33309456  java.lang.String
  11:        384915       31853656  [Ljava.util.concurrent.ConcurrentHashMap$Node;
  12:        491135       15716320  java.util.Collections$UnmodifiableMap
  13:        467634       14964288  java.util.concurrent.ConcurrentHashMap$Node
  14:        217275       12167400  java.util.LinkedHashMap
  15:        178082       11397248  org.apache.dubbo.common.url.component.ServiceConfigURL
  16:        278098       11123920  java.util.LinkedHashMap$Entry
  17:        178163        9977128  org.apache.dubbo.common.url.component.PathURLAddress
  18:        180205        8649840  org.apache.dubbo.common.url.component.URLParam
  19:        130564        8356096  org.apache.dubbo.rpc.model.ConsumerModel
  20:        130566        7311696  org.apache.dubbo.rpc.model.ServiceMetadata
  21:        130564        7311584  org.apache.dubbo.rpc.protocol.dubbo.DubboInvoker
  22:        183196        7181480  [I
```


```sh
/data/java/jdk1.8.0_45/bin/jmap -heap 26106

Attaching to process ID 26106, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.45-b02

using thread-local object allocation.
Parallel GC with 2 thread(s)

Heap Configuration:
   MinHeapFreeRatio         = 0
   MaxHeapFreeRatio         = 100
   MaxHeapSize              = 2025848832 (1932.0MB)
   NewSize                  = 42467328 (40.5MB)
   MaxNewSize               = 675282944 (644.0MB)
   OldSize                  = 85458944 (81.5MB)
   NewRatio                 = 2
   SurvivorRatio            = 8
   MetaspaceSize            = 21807104 (20.796875MB)
   CompressedClassSpaceSize = 1073741824 (1024.0MB)
   MaxMetaspaceSize         = 17592186044415 MB
   G1HeapRegionSize         = 0 (0.0MB)

Heap Usage:
PS Young Generation
Eden Space:
   capacity = 556269568 (530.5MB)
   used     = 535328408 (510.5289535522461MB)
   free     = 20941160 (19.971046447753906MB)
   96.23542951031972% used
From Space:
   capacity = 11534336 (11.0MB)
   used     = 0 (0.0MB)
   free     = 11534336 (11.0MB)
   0.0% used
To Space:
   capacity = 24117248 (23.0MB)
   used     = 0 (0.0MB)
   free     = 24117248 (23.0MB)
   0.0% used
PS Old Generation
   capacity = 1350565888 (1288.0MB)
   used     = 1350143192 (1287.5968856811523MB)
   free     = 422696 (0.40311431884765625MB)
   99.9687023044373% used

28135 interned Strings occupying 2893296 bytes.

```
## Links

- [jstat 分析GC+内存占用](https://www.cnblogs.com/StarbucksBoy/p/11342188.html)
- [jcmd](https://www.cnblogs.com/webor2006/p/10669472.html)
- [jvm 常用的命令](https://www.cnblogs.com/duanxz/p/6115722.html)