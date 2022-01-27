# GC

- G1
- G1 的老年代和年轻代不再是一块连续的空间，整个堆被划分成若干个大小相同的 Region，也就是区
- Region 的类型有 Eden、Survivor、Old、Humongous 四种
- 写屏障主要有两个作用：
- 在并发标记阶段解决活跃对象漏标问题；
- 在写屏障里使用 card table 维护跨代引用
- deletion barrier
- 开始时快照（Snapshot At The Beginning，SATB)
- SATB 队列
- young GC 和 mixed GC
- young GC：只回收年轻代的 Region
- mixed GC：回收全部的年轻代 Region，并回收部分老年代的 Region
- 回收集合（Collection Set，CSet)
- dirty card queue（DCQ）
- G1 Evacuation
- prevBitMap
- nextBitMap
- MaxGCPauseMillis
- InitiatingHeapOccupancyPercent (IHOP)

## G1 CSet

我们把 mixed GC 中选取的老年代对象 Region 的集合称之为回收集合（Collection Set，CSet）。
CSet 的选取要素有以下两点：该 Region 的垃圾占比。垃圾占比越高的 Region，被放入 CSet 的优先级就越高，
这就是垃圾优先策略（Garbage First），也是 G1 GC 名称的由来。建议的暂停时间。
建议的暂停时间由 -XX:MaxGCPauseMillis 指定，G1 会根据这个值来选择合适数量的老年代 Region。


如果一个应用会频繁触发 G1 GC 的 Full GC，那么说明这个应用的 GC 参数配置是不合理的，理想情况下 G1 是没有 Full GC 的

## G1 RSet 

记录集（Remembered Set，RSet

RSet 需要维护的引用关系只有两种，非 CSet 老年代 Region 到年轻代 Region 的引用，和非 CSet 老年代 Region 到 CSet 老年代 Region 的引用。
