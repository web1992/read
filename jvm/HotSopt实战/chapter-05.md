# 第五章 垃圾收集

- 垃圾收集 Garbage Collection GC
- 垃圾收集器(Garbage Collector)
- 确保仍被引用的对象在内存中保持存在
- 回收无任何引用的对象所占用的内存空间
- 避免内存碎片(memory fragmentation)的同时还要兼顾分配与回收的效率
- 分代+分代收集 
- 标记清除算法 Mark-Sweep)
- 复制算法 Copying
- 标记压缩算法 Mark-Compact
- 晋升 Promotion
- TLABS Thread Local Allaction Buffers
- UseTLAB
- 栈上分配
- 在栈中分配的基本思路是这样的:分析局部变量的作用域仅限于方法内部，则JVM直接在栈帧内分配对象空间，避免在堆中分配
- gcCause.hpp
- VM_Operation VM_GC_Operation VM_CMS_Operation
- STW stop the world
- Serial收集器，作用于新生代，基于“复制”算法
- Serial Old收集器，作用于老年代，基于“标记-整理”算法
- ParNew收集器，作用于新生代，基于“复制”算法，图5-7描述了ParNew 的主要组成模块
- Parallel Old收集器，作用于老年代，基于“标记-整理”算法
- 吞吐量优先收集器: Parallel Scanvenge
- -XX:MaxGCPauseMillis:期望收集时间.上限。用来控制收集对应用程序停顿的影响。
- -XX:GCTimeRatio:期望的GC时间占总时间的比例，用来控制吞吐量。
- -XX:UseAdaptiveSizePolicy:自 动分代大小调节策略。
- 如何找到垃圾-可达性分析
- 可达性(reachability)
- 可达性分析(reachability analysis)
- 安全点 safepoint
- 初始标记
- 并发标记
- G1 Region
- -verbose:gc
- -XX:PrintGC 等同于"-verbose.gc"
- -XX:PrintGCDetails GC时输出更多细节信息
- -XX:PrintGCDateStamps GC操作的日期戳信息，相对于时间戳，这个是GST时间
- -XX:PrintGCTimeStamps  GC时的时间戳信息
- -XX:PrintGCTaskTimeStamps 输出每个GC工作线程的时间戳信息
- -Xloggc: <filename> 输出GC日志至文件
- -XX:+ShowSafepointMsgs 输出安全点信息

## 垃圾收集器

- 吞吐量:应用程序运行时间/(应用程序运行时间+垃圾收集时间)。即没有花在垃圾.
- 收集的时间占总时间的比例。
- 垃圾收集开销:与吞吐量相对，这表示垃圾收集耗用时间占总时间的比例。
- 暂停时间:在垃圾收集操作发生时，应用程序被停止执行的时间。
- 收集频率:相对于应用程序的执行，垃圾收集操作发生的频率。
- 堆空间:堆空间所占内存大小。
- 及时性:一个对象由成为垃圾到被回收所经历的时间。


根据垃圾收集作用在不同的分代，垃圾收集类型分为两种。
- Minor Collection:对新生代进行收集。
- Full Collection:

除了对新生代收集外，也对老年代或永久代进行收集，又称为MajorCollection。Full Collection 对所有分代都进行了收集:首先，按照新生代配置的收集算法对新生代进行收集;接着，使用老年代收集算法对老年代和永久代进行收集。一般来说，相较于Minor Collection，这种收集行为的频率较低，但耗时较长。

## 对象的晋升

JVM通过两类参数判断对象是否可以晋升到老年代。
- 年龄: 在Minor Collection后仍然存活的对象，其经历的Minor Collection 次数，就表示该对象的年龄
- 大小:对象占用的空间大小

## 可达性(reachability)

本身是根对象。根(root)是指由堆以外空间访问的对象。JVM中会将一组对 象标记为根，包括全局变量、部分系统类，以及栈中引用的对象，如当前栈帧中的局部变量和参数。被一个可达的对象引用。

## 安全点 safepoint

JVM在暂停的时候，需要选准一一个时机，由于JVM系统运行期间的复杂性，不可能做到随时暂停，因此引入了安全点(safepoint) 概念:程序只有在运行到安全点的时候，才准暂停下来。HotSpot采用`主动中断`的方式，让执行线程在运行时轮询是否需要暂停的标识，若需要暂停则中断挂起。HotSpot使用了几条短小精炼的汇编指令便可完成安全点轮询以及触发线程中断，因此对系统性能的影响可以忽略不计。

## CMS

- 初始标记( initial-mark):从根对象节点仅扫描与根节点直接关联的对象并标记，这个
过程必须STW，但由于根对象数量有限，所以这个过程很短暂。

- 并发标记( concurrent-marking):与用户 线程并发进行。这个阶段紧随初始标记阶段，
在初始标记的基础上继续向下追溯标记。并发标记阶段，应用程序的线程和并发标记
的线程并发执行，所以用户不会感受到停顿。

> CMS希望从根节点出发的对象引用关系不被破坏就行。

- 并发预清理( concurrent-precleaning):与应用线程并发进行。由于上一阶段执行期间，
会出现一些趁机“晋升”到老年代的对象。在该阶段通过重新扫描，减少下一个阶段“重新标记”的工作，因为下一个阶段会STW。
- 重新标记(remark): STW， 但很短暂。暂停工作线程，由GC线程扫描在CMS堆中的对象。这个过程主要是在前期标记的基础上，仅对并发标记阶段遭到破坏的的对象引用关系进行修复，以保证最终“清理”前建立的对象引用关系是正确的。扫描将从根对象开始向下追溯，并处理对象关联。这个过程也很短暂。
- 并发清理( concurrent-sweeping):清理垃圾对象，这个阶段GC线程和应用线程并发执行。
- 并发重置( concurrent-reset):这个阶段，重置CMS收集器的数据结构，做好下一次执行GC任务的准备工作。

## 何时使用G1

对于打算从CMS或ParallelOld收集器迁移过来的应用，按照官方的建议,如果发现符合如下特征，可以考虑更换成G1收集器以追求更佳性能:
- 实时数据占用了超过半数的堆空间;
- 对象分配率或“晋升”的速度变化明显;
- 期望消除耗时较长的GC或停顿(超过0.5~1秒)。

> 注意
官方建议， 如果应用程序此前在使用CMS或ParallelOldGC收集器时运行良好，并没有造成应用程序出现长时间的停顿，那么最好的建议就是维持现状，而不是切换到G1收集器。当你选择升级到最新的JDK时，并不意味着一定要将收集器也切换到新的收集器上。


## G1 Region

![jvm-g1-heap-Layout.drawio.svg](./images/jvm-g1-heap-Layout.drawio.svg)


## G1 回收的过程


- (1)初始标记(InitialMark):STW。G1将这个过程伴随在一次普通的新生代GC中完成。该阶段标记的是幸存区Regions (Root Regions)。当然，该区域仍有可能引用老年代的对象。
- (2)根区域扫描( Root Region Scanning):扫描幸存区中引用老年代的Regions。该阶段与应用程序并发进行。这一过程必须能够在新生代GC发生前完成。
- (3)并发标记(Concurrent Marking):找出全堆中存活对象。该阶段与应用程序并发进行。这一过程允许被新生代GC打断。
- (4)重新标记(Remark): STW，完成堆中存活对象的标记。重新标记基于SATB算法(snapshot-at-the-beginning)，比CMS收集器算法快很多。
- (5)清理(Cleanup)。包括3个阶段:首先，计算活跃对象并完全释放自由Regions(STW);然后，处理Remembered Sets (STW);最后，重置空闲regions并将它们放回空闲列表(并发)。
- (6)复制(Copying): STW。 将存活对象疏散或复制至新的未使用区域内。


## GC 日志

- -XX:PrintGC 等同于"-verbose.gc"
- -XX:PrintGCDetails GC时输出更多细节信息
- -XX:PrintGCDateStamps GC操作的日期戳信息，相对于时间戳，这个是GST时间
- -XX:PrintGCTimeStamps  GC时的时间戳信息
- -XX:PrintGCTaskTimeStamps 输出每个GC工作线程的时间戳信息
- -Xloggc: <filename> 输出GC日志至文件

- PrintGCTimeStamps 绝对时间，比如2022-06-01 10:59:59
- PrintGCDateStamps 相对时间，比如 5.20