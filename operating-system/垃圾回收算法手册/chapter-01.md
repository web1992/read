# 第一章 引言

关键字：

- 悬挂指针 danging pointer
- 内存泄漏 memory leak
- 肥指针 fat pointer
- 安全性
- 吞吐量
- 赋值器 mutator
- 赋值器根 Root
- 回收器
- 分配器 allocator
- 完整性与及时性
- 平均停顿时间(pause time)
- 浮动垃圾(floating garbage)
- MMU minimum mutator utilization
- BMU bounded mutator utilization
- 空间开销
- 记忆集 remembered set
- 跨区域指针
- 浮动垃圾 floating garbage
- 内存块 chunk
- 高速缓存行(cache line) 高速缓存块(cache block )
- 存活性、正确性以及可达性
- 并行回收
- 增量回收
- 并发回收
- 实时回收
- 标记清扫算法
- 标记整理算法
- 复制回收算法
- 引用计数算法

## 显式内存释放 vs 自动动态内存管理

自动动态内存管理可以解决大多数悬挂指针和内存泄漏问题。垃圾回收(garbage collection, GC) 
可以将未被任何可达对象引用的对象回收，从而避免`悬挂指针`的出现。原则上讲，回收器最终都会将所有不可达对象回收，但是有两个注意事项:
第一，追踪式回收(tracing collection)引人“垃圾”这一具有明确判定标准的概念，但它不一定包含所有不再使用的对象;
第二，后面章节将要描述，在实际情况下，出于效率原因，某些对象可能不会被回收。只有回收器可以释放对象，所以不会出现二次释放(double-freeing)问题。

回收器掌握堆中对象的`全局信息`以及所有可能访问堆中对象的线程信息，因而其可以决定任意对象是否需要回收。
显式释放的主要问题在于其无法在局部上下文中掌握全局信息，而自动动态内存管理则简单地解决了这一问题。

## 垃圾回收算法之间的比较

所指出的“存活性是-个全局(global)特征”，但是调用 free 函数将对象释放却是局部行为，所以如何将对象正确地释放是一个十分复杂的问题。

- 安全性
  垃圾回收器首先要考虑的因素是安全性(safety),即在任何时候都不能回收存活对象。
  但安全性是需要付出一定代价的，特别是在并发回收器中(参见第 15 章)。

- 吞吐量

对程序的最终用户而言，程序当然是运行得越快越好，但这是由几方面因素决定的。其中的一方面便是花费在垃圾回收上的时间应当越少越好，文献中通常用标记/构造率(mark/cons ratio)来衡量这一指标。
这一概念是在早期的 Lisp 语言中最先提出的，它表示回收器(对存活对象进行标记)与赋值器(mutator)(创建或者构造新的链表单元)活跃度的比值。
然而在大多数设计良好的架构中，赋值器会比回收器占用更多的 CPU 时间，因此在适当牺牲回收器效率的基础上提升赋值器的吞吐量，
并进一步提升整个程序 (赋值器+回收器)的执行速度，一般来说是值得的。例如，使用标记一清扫回收的系统偶尔会执行存活对象整理以
减少内存碎片，虽然这一操作开销较大，但它可以提升赋值器的分配性能。

- 完整性与及时性

理想情况下，垃圾回收过程应当是完整的，即堆中的所有垃圾最终都应当得到回收，但这通常是不现实的，甚至是不可取的，例如纯粹的引用计数回收器便无法回收环状引用垃圾(自引用结构)。从性能方面考虑，在一次回收过程(collection cycle)中只处理堆中部分对象或许更加合理，例如分代回收器会依照堆中对象的年龄将其划分为两代或者更多代(我们将在第 9 章描述分代垃圾回收)，并把回收的主要精力集中在年轻代，这样不仅可以提高回收效率，而且可以减少单次回收的平均停顿时间(pause time)。

在并发垃圾回收器中，赋值器与回收器同时工作，其目的在于避免或者尽量减少用户程序的停顿。此类回收器会遇到浮动垃圾(floating garbage)问题，即如果某个对象在回收过程启动之后才变成垃圾，那么该对象只能在下一个回收周期内得到回收。因此在并发回收器中，衡量完整性更好的方法是统计所有垃圾的最终回收情况，而不是单个回收周期的回收情况。不同的回收算法在回收及时性(promptness)方面存在较大差异，进而需要在`时间`和`空间`上进行权衡。

- 停顿时间

许多回收器在进行垃圾回收时需要中断赋值器线程，因此会导致在程序执行过程中出现停顿。回收器应当尽量减少对程序主要执行过程的影响，因此要求停顿时间越短越好，这一点对于交互式程序或者事务处理服务器(超时将引发事务的重试，进而导致事务的积压)尤为重要。但正如我们在后面章节中将要看到的，限制停顿时间会带来一些副作用。 例如，分代式回收器通过频繁且快速地回收较小的、较为年轻的对象来缩短停顿时间，而对较大的、较为年老对象的回收则只是偶尔进行。显然，在对分代回收器进行调优时，需要平衡不同分代的大小，进而才能平衡不同分代之间的停顿时间与回收频率。但由于分代回收器必须记录一些分代间指针的来源，因此赋值器的指针写操作会存在少量的额外开销。

例如标准差或者图形表示等。更有效的方法包括最小赋值器使用率(minimum mutator utilization， MMU)和界限赋值器使用率(bounded mutator utilization, BMU)

- 存活性、正确性以及可达性

如果某一对象在程序的后续执行过程中可能会被赋值器访问，则称该对象是存活(live)的。回收器的正确性是指其永远不会回收依然存活的对象，但对于应用程序而言，存活性
(liveness)是一个不确定的特征:一般的程序无法确定赋值器是否永远不会再访问某个堆中对象，因为程序持有一个对象的指针并不意味着会对其进行访问。
幸运的是，我们可以将指针可达性(pointer reachability)这个可确定因素作为对象是否存活的近似等价，即:如果从对象M的域f出发，经过一条指针链最终可以到达对象N,则称对象N从对象M可达。因此如果从赋值器根出发，经过一条指针链可以到达某一对象，赋值器才有可能访问到该对象。


## 赋值器与回收器

对于使用垃圾回收的程序，Dijkstra 等[1976、1978] 将其执行过程划分为两个半独立的部分:

- 赋值器执行应用代码。这一过程会分配新的对象，并且修改对象之间的引用关系，进而改变堆中对象图的拓扑结构，引用域可能是堆中对象，也可能是根，例如静态
变量、线程栈等。随着引用关系的不断变更，部分对象会失去与根的联系，即从根出发沿着对象图的任何一条边进行遍历都无法到达该对象。

- 回收器(collector)执行垃圾回收代码，即找到不可达对象并将其回收。
一个程序可能拥有多个赋值器线程，但是它们共用同一个堆。相应的，也可能存在多个回收器线程。

- 分配器 allocator

分配器(allocator) 与回收器在功能上是正交关系。分配器支持两种操作:分配(allocate)和释放(free)。 
分配是为某一对象保留底层的内存存储，释放是将内存归还给分配器以便复用。分配存储空间的大小是由一个可选参数来控制的，
如果我们在伪代码中忽略这一参数，意味着分配器将返回一个固定大小的对象，或者对象大小对于算法的理解并非必要。
分配操作也可能支持更多参数，例如将数组的分配与单个对象的分配进行区分，或者将指针数组的分配和不包含指针的数组进行区分，
或者包含其他一些必要信息以便初始化对象头部。

- 赋值器的读写操作

赋值器线程在工作过程中会执行三种与回收器相关的操作:创建(New)、 读(Read)、写(write)。
我们约定，赋值器操作的命名均采用首字母大写的方式，与回收器相关的操作则均采用首字母小写。
这些操作通常都会有顾名思义的行为:分配一个新对象、读一个对象的域、写一个对象的域。某些特殊的内存管理器会为基本操作增加一些额外功能，即屏障
(barrier)，屏障操作会同步或者异步地与回收器产生交互。在后文，我们将区分读屏障(read barrier)和写屏障(write barrier)。
