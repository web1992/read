# 第 8 章　对象管理功能

- CollectedHeap GC 接口
- CollectorPolicy GC 策略
- AllStatic 类
- CHeapObj 类
- GrowableArray



## CollectedHeap CollectorPolicy

CollectedHeap类是接口。CollectedHeap类根据CollectorPolicy类内的设定值来决定GC 策略。而CollectedHeap类对各个 GC 类发送请求，要求它们对堆内部执行 GC。首先，我们来看一看这张全貌图中的出场角色。CollectedHeap类负责管理用来分配对象的 VM 堆。另外，它还具有对象管理功能接口的作用，会根据CollectorPolicy类中的数据进行合适的处理。


## 启动选项和使用的 VM 堆类


|启动选项GC| 算法VM| 堆类|
|---------|-------|----|
|XX:UseSerialGC         |串行 GC |GenCollectedHeap|
|-XX:UseParallelGC      |并行 GC |ParallelScavengeHeap
|-Xincgc                |增量 GC |GenCollectedHeap
|-XX:UseConcMarkSweepGC |并发 GC |GenCollectedHeap
|-XX:UseG1GC            |G1GC   |G1CollectedHeap


## 启动选项和使用的策略

|启动选项|策略|
|-------|---|
|-XX:UseSerialGC                 |MarkSweepPolicy |
|-XX:UsePararllelGC              |GenerationSizer |
|-XincgcConcurrentMarkSweePolicy |（CMSIncrementalMode=true）|
|-XX:UseConcMarkSweepGC          |ConcurrentMarkSweePolicy |
|-XX:UseG1GC                     |G1CollectorPolicy_BestRegionsFirst|

