# proc status

JVM native memory 跟踪

- -XX:+UnlockDiagnosticVMOptions -XX:+PrintNMTStatistics JVM退出时打印NMT报告
- -XX:NativeMemoryTracking=[off | summary | detail]
- jcmd 23633 VM.native_memory summary scale=MB

- jcmd <pid> VM.native_memory baseline
- jcmd <pid> VM.native_memory summary.diff

```sh
jcmd 14875 VM.native_memory summary scale=MB
jcmd 14875 VM.native_memory baseline
/data/java/jdk/bin/jcmd 14875 VM.native_memory summary.diff scale=MB > 14875-mem-diff-3.txt
```

```sh
/usr/local/jdk1.8.0_152/bin/java -Xms512m -Xmx512m -Xmn256m -XX:+UnlockDiagnosticVMOptions -XX:+PrintNMTStatistics -XX:NativeMemoryTracking=detail -jar spring-native-mem-leak-0.0.1-SNAPSHOT.jar
```

```sh
## cat /proc/2936/status
Name:   java
Umask:  0002
State:  S (sleeping)
Tgid:   2936
Ngid:   0
Pid:    2936
PPid:   1
TracerPid:      0
Uid:    1999    1999    1999    1999
Gid:    1999    1999    1999    1999
FDSize: 1024
Groups: 1999
VmPeak: 10125728 kB
VmSize:  9994656 kB
VmLck:         0 kB
VmPin:         0 kB
VmHWM:   3996064 kB
VmRSS:   3988836 kB
RssAnon:         3981328 kB
RssFile:            7508 kB
RssShmem:              0 kB
VmData:  9806124 kB
VmStk:       132 kB
VmExe:         4 kB
VmLib:     18216 kB
VmPTE:     11400 kB
VmSwap:        0 kB
Threads:        735
SigQ:   0/30818
SigPnd: 0000000000000000
ShdPnd: 0000000000000000
SigBlk: 0000000000000000
SigIgn: 0000000000000003
SigCgt: 2000000181005ccc
CapInh: 0000000000000000
CapPrm: 0000000000000000
CapEff: 0000000000000000
CapBnd: 0000001fffffffff
CapAmb: 0000000000000000
NoNewPrivs:     0
Seccomp:        0
Speculation_Store_Bypass:       vulnerable
Cpus_allowed:   f
Cpus_allowed_list:      0-3
Mems_allowed:   00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000001
Mems_allowed_list:      0
voluntary_ctxt_switches:        15
nonvoluntary_ctxt_switches:     6
```

## jcmd

```sh
jcmd 15048 VM.native_memory
```

```log

15048:

Native Memory Tracking:

Total: reserved=4209123KB, committed=3042659KB
-                 Java Heap (reserved=2097152KB, committed=2097152KB)
                            (mmap: reserved=2097152KB, committed=2097152KB)

-                     Class (reserved=1217293KB, committed=184077KB)
                            (classes #22691)
                            (malloc=8973KB #62583)
                            (mmap: reserved=1208320KB, committed=175104KB)

-                    Thread (reserved=320155KB, committed=320155KB)
                            (thread #311)
                            (stack: reserved=318640KB, committed=318640KB)
                            (malloc=1022KB #1556)
                            (arena=492KB #621)

-                      Code (reserved=282618KB, committed=149370KB)
                            (malloc=33018KB #27303)
                            (mmap: reserved=249600KB, committed=116352KB)

-                        GC (reserved=82437KB, committed=82437KB)
                            (malloc=5813KB #1421)
                            (mmap: reserved=76624KB, committed=76624KB)

-                  Compiler (reserved=913KB, committed=913KB)
                            (malloc=783KB #1174)
                            (arena=131KB #3)

-                  Internal (reserved=171847KB, committed=171847KB)
                            (malloc=171815KB #81744)
                            (mmap: reserved=32KB, committed=32KB)

-                    Symbol (reserved=29172KB, committed=29172KB)
                            (malloc=25297KB #271145)
                            (arena=3876KB #1)

-    Native Memory Tracking (reserved=7339KB, committed=7339KB)
                            (malloc=278KB #4248)
                            (tracking overhead=7061KB)

-               Arena Chunk (reserved=196KB, committed=196KB)
                            (malloc=196KB)

```


## Linux 


```sh
HEAPPROFILE=/data/applogs/heap.log 
HEAP_PROFILE_ALLOCATION_INTERVAL=104857600 
LD_PRELOAD=/usr/local/lib/libtcmalloc_and_profiler.so
```

内存分析工具 gperftools

## Links

- [gperftools](https://github.com/gperftools/gperftools/)
- [jmap工具](https://blog.csdn.net/claram/article/details/104635114)
- [jcmd工具](https://www.cnblogs.com/duanxz/p/6115722.html)
- [JVM NMT](https://www.jianshu.com/p/27c06a43797b)

## pprof

```shell
pprof --svg  /data/java/jdk/bin/java --base=heap.log_2144.1670.heap heap.log_2144.1704.heap > 2144_44.svg
```

pprof --svg  /data/java/jdk/bin/java --base=mem-all.log_13823.0001.heap mem-all.log_13823.0330.heap > /data/applogs//0001.svg

pprof --svg  /data/java/jdk/bin/java --base=mem-all.log_14875.1300.heap mem-all.log_14875.1375.heap > /data/applogs/10002.svg


pprof --svg  /data/java/jdk/bin/java   mem-all.log_14875* > /data/applogs/10005.svg