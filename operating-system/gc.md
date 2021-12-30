# GC

- 分配的效率
- 回收的效率
- 是否产生内存碎片
- 空间利用率
- 是否停顿
- 以及实现的难度
- 用计数法和基于可达性分析的算法
- 分代垃圾回收算法
- JVM Scavenge GC 算法
- 碰撞指针（Bump-pointer）
- 深度优先遍历（Depth First Search， DFS）
- 广度优先遍历（Breadth First Search，BFS）
- Mark-Sweep 算法
- 标记位图
- 晋升 (Promotion)
- 跨代引用 记录集（Remember Set，RS）
- 写屏障：维护记录集 (效率较差)
- Card table （Card table 这种实现方式来提升写屏障的（记录集）效率）（借鉴位图）
- 记录集（Remembered Set，RSet）
- CMS 并发标记清除算法（Concurrent Mark Sweep，CMS）
- 漏标
- 分区回收算法 (G1)
- G1 分区(Eden、Survivor、Old、Humongous)
- 难点：维护跨分区引用
- 开始时快照（Snapshot At The Beginning，SATB）
- SATB 队列
- young GC：只回收年轻代的 Region
- mixed GC：回收全部的年轻代 Region，并回收部分老年代的 Region
- 维护跨区引用 RSet
- 稀疏表、细粒度表和粗粒度表
- G1 Evacation 的过程
- nextBitMap
- prevBitMap
- ZGC
- 着色指针
- 读屏障技术
- Marked0、Marked1、Remapped、Finalizable 四个地址视图
- Mark、Relocate 和 Remap

## Mark-Sweep 算法

简单来讲，Mark-Sweep 算法由 Mark 和 Sweep 两个阶段组成。
在 Mark 阶段，垃圾回收器遍历活跃对象，将它们标记为存活。
在 Sweep 阶段，回收器遍历整个堆，然后将未被标记的区域回收。

Mark-Sweep 算法回收的是垃圾对象，如果垃圾对象比较少，回收阶段所做的事情就比较少。所以它适合于存活对象多，垃圾对象少的情况。
基于 copy 的垃圾回收算法 Scavenge，搬移的是活跃对象，所以它更适合存活对象少，垃圾对象多的情况

## 分代回收

对于存活时间比较短的对象，我们可以用 Scavenge 算法回收；
对于存活时间比较长的对象，就可以使用 Mark-Sweep 算法。这就是分代垃圾回收算法产生的动机。

在进行年轻代垃圾回收时，为了找出从老年代到年轻代的引用，可以考虑对老年代对象进行遍历。
但如果这么做的话，年轻代 GC 执行时，就会对全部对象进行遍历，分代就没意义了。

## 三色抽象

白色：还未搜索的对象；
灰色：已经搜索，但尚未扩展的对象；
黑色：已经搜索，也完成扩展的对象。

## 写屏障

写屏障主要有两个作用：
- 在并发标记阶段解决活跃对象漏标问题；
- 在写屏障里使用 card table 维护跨代引用。

## Hotspot 中 CMS 的实现

Hotspot 中，CMS 是由多个阶段组成的，主要包括初始标记、并发标记、重标记、并发清除，以及最终清理等。其中：初始标记阶段，标记老年代中的根对象，因为根对象中包含从栈上出发的引用等比较敏感的数据，并发控制难以实现，所以这一阶段一般都采用 Stop The World 的做法。这里一般不遍历年轻代对象，也就是不关注从年轻代指向老年代的引用。并发标记阶段，这一阶段就是在上面内容中讲到的三色标记算法中做了一些改动，我们会在后面的内容中详细分析这一阶段的实现。重标记阶段，这一阶段会把年轻代对象也进行一次遍历，找出年轻代对老年代的引用，并且为并发标记阶段扫尾。并发清除阶段，这一阶段会把垃圾对象归还给 freelist，只要注意好 freelist 的并发访问，实现垃圾回收线程和业务线程并发执行是简单的。最终清理阶段，清理垃圾回收所使用的资源。为下一次 GC 执行做准备。

## G1

我们把 mixed GC 中选取的老年代对象 Region 的集合称之为回收集合（Collection Set，CSet）。
CSet 的选取要素有以下两点：
- 该 Region 的垃圾占比。垃圾占比越高的 Region，被放入 CSet 的优先级就越高，这就是垃圾优先策略（Garbage First），也是 G1 GC 名称的由来。
- 建议的暂停时间。建议的暂停时间由 -XX:MaxGCPauseMillis 指定，G1 会根据这个值来选择合适数量的老年代 Region。

G1 的垃圾清理是通过把活跃的对象，从一个 Region 拷贝到另一个空白 Region，这个空白 Region 隶属于 Survivor 空间。这个过程在 G1 GC 中被命名为转移（Evacation）。它和之前讲到的基于 copy 的 GC 的最大区别是：它可以充分利用 concurrent mark 的结果快速定位到哪些对象需要被拷贝。

## Links

- [https://tech.meituan.com/2020/08/06/new-zgc-practice-in-meituan.html](https://tech.meituan.com/2020/08/06/new-zgc-practice-in-meituan.html)