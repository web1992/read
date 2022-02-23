# G1

关键字：
- “停顿时间模型”
- G1 的老年代和年轻代不再是一块连续的空间，整个堆被划分成若干个大小相同的 Region，也就是区
- Region 的类型有 Eden、Survivor、Old、Humongous 四种
- 写屏障主要有两个作用：
- 在并发标记阶段解决活跃对象漏标问题；
- 在写屏障里使用 card table 维护跨代引用
- deletion barrier
- write barrier
- 开始时快照（Snapshot At The Beginning，SATB)
- SATB 队列
- young GC 和 mixed GC
- young GC：只回收年轻代的 Region
- mixed GC：回收全部的年轻代 Region，并回收部分老年代的 Region
- 回收集合（Collection Set，CSet)
- dirty card queue（DCQ）
- G1 Evacuation
- TAMS（Top at Mark Start）的指针
- prevBitMap
- nextBitMap
- MaxGCPauseMillis
- InitiatingHeapOccupancyPercent (IHOP)
- 初始标记（Initial Marking）
- 并发标记（Concurrent Marking）
- 最终标记（Final Marking）
- 筛选回收（Live Data Counting and Evacuation)

## 概述

从下面几个方面去理解G1回收。

- 内存布局
- 内存分配
- 内存回收
- 关键技术

## 内存布局

## 内存分配

## 内存回收

## 关键技术


G1它可以面向堆内存任何部分来组成回收集（Collection Set，一般简称CSet）进行回收，衡量标准不再是它属于哪个分代，而是哪块内存中存放的垃圾数量最多，回收收益最大，这就是G1收集器的Mixed GC模式。

## 低延迟 吞吐量

从上述阶段的描述可以看出，G1收集器除了并发标记外，其余阶段也是要完全暂停用户线程的，
换言之，它并非纯粹地追求低延迟，官方给它设定的目标是在延迟可控的情况下获得尽可能高的吞吐量，所以才能担当起“全功能收集器”的重任与期望

从G1开始，最先进的垃圾收集器的设计导向都不约而同地变为追求能够应付应用的内存分配速率
（Allocation Rate），而不追求一次把整个Java堆全部清理干净。这样，应用在分配，同时收集器在收
集，只要收集的速度能跟得上对象分配的速度，那一切就能运作得很完美。这种新的收集器设计思路
从工程实现上看是从G1开始兴起的，所以说G1是收集器技术发展的一个里程碑。

## G1 CSet

我们把 mixed GC 中选取的老年代对象 Region 的集合称之为回收集合（Collection Set，CSet）。
CSet 的选取要素有以下两点：该 Region 的垃圾占比。垃圾占比越高的 Region，被放入 CSet 的优先级就越高，
这就是垃圾优先策略（Garbage First），也是 G1 GC 名称的由来。建议的暂停时间。
建议的暂停时间由 -XX:MaxGCPauseMillis 指定，G1 会根据这个值来选择合适数量的老年代 Region。


如果一个应用会频繁触发 G1 GC 的 Full GC，那么说明这个应用的 GC 参数配置是不合理的，理想情况下 G1 是没有 Full GC 的

## G1 RSet 

记录集（Remembered Set，RSet

RSet 需要维护的引用关系只有两种，非 CSet 老年代 Region 到年轻代 Region 的引用，和非 CSet 老年代 Region 到 CSet 老年代 Region 的引用。


## 低延迟垃圾收集器

衡量垃圾收集器的三项最重要的指标是：内存占用（Footprint）、吞吐量（Throughput）和延迟
（Latency），三者共同构成了一个“不可能三角[1]”。三者总体的表现会随技术进步而越来越好，但是
要在这三个方面同时具有卓越表现的“完美”收集器是极其困难甚至是不可能的，一款优秀的收集器通
常最多可以同时达成其中的两项。