# 第 12 章　 Java 内存模型与线程

- 每秒事务处理数（Transactions Per Second,TPS）
- QPS,Queries Per Second，意思是“每秒查询率”
- Java 内存模型
- 先行发生原则，用来确定一个操作在并发环境下是否安全的
- Java 内存模型 的内存操作 lock、unlock、read、load、assign、use、store、write
- 原子性、可见性与有序性
- 线程的实现
- Java 线程的实现
- Java 线程调度
- 状态转换

## 缓存一致性

“让计算机并发执行若干个运算任务”与“更充分地利用计算机处理器的效能”之间的因果关系，看起来理所当然，实际上它们之间的关系并没有想象中那么简单，其中一个重要的复杂性的来源是绝大多数的运算任务都不可能只靠处理器“计算”就能完成。处理器至少要与内存交互，如读取运算数据、存储运算结果等，这个 I/O 操作就是很难消除的（无法仅靠寄存器来完成所有运算任务）。由于计算机的存储设备与处理器的运算速度有着几个数量级的差距，所以现代计算机系统都不得不加入一层或多层读写速度尽可能接近处理器运算速度的高速缓存（Cache）来作为内存与处理器之间的缓冲：将运算需要使用的数据复制到缓存中，让运算能快速进行，当运算结束后再从缓存同步回内存之中，这样处理器就无须等待缓慢的内存读写了。

基于高速缓存的存储交互很好地解决了处理器与内存速度之间的矛盾，但是也为计算机系统带来更高的复杂度，它引入了一个新的问题：缓存一致性（CacheCoherence）。在多路处理器系统中，每个处理器都有自己的高速缓存，而它们又共享同一主内存（MainMemory），这种系统称为共享内存多核系统（SharedMemoryMultiprocessorsSystem），如图 121 所示。当多个处理器的运算任务都涉及同一块主内存区域时，将可能导致各自的缓存数据不一致。如果真的发生这种情况，那同步回到主内存时该以谁的缓存数据为准呢？为了解决一致性的问题，需要各个处理器访问缓存时都遵循一些协议，在读写时要根据协议来进行操作，这类协议有 MSI、MESI（IllinoisProtocol）、MOSI、Synapse、Firefly 及 DragonProtocol 等。从本章开始，我们将会频繁见到“内存模型”一词，它可以理解为在特定的操作协议下，对特定的内存或高速缓存进行读写访问的过程抽象。不同架构的物理机器可以拥有不一样的内存模型，而 Java 虚拟机也有自己的内存模型，并且与这里介绍的内存访问操作及硬件的缓存访问操作具有高度的可类比性。

## Java 内存模型

Java 内存模型的主要目的是定义程序中各种变量的访问规则，即关注在虚拟机中把变量值存储到内存和从内存中取出变量值这样的底层细节。此处的变量（Variables）与 Java 编程中所说的变量有所区别，它包括了实例字段、静态字段和构成数组对象的元素，但是不包括局部变量与方法参数，因为后者是线程私有的[1]，不会被共享，自然就不会存在竞争问题。为了获得更好的执行效能，Java 内存模型并没有限制执行引擎使用处理器的特定寄存器或缓存来和主内存进行交互，也没有限制即时编译器是否要进行调整代码执行顺序这类优化措施。

Java 内存模型规定了所有的变量都存储在主内存（MainMemory）中（此处的主内存与介绍物理硬件时提到的主内存名字一样，两者也可以类比，但物理上它仅是虚拟机内存的一部分）。每条线程还有自己的工作内存（WorkingMemory，可与前面讲的处理器高速缓存类比），线程的工作内存中保存了被该线程使用的变量的主内存副本[2]，线程对变量的所有操作（读取、赋值等）都必须在工作内存中进行，而不能直接读写主内存中的数据[3]。不同的线程之间也无法直接访问对方工作内存中的变量，线程间变量值的传递均需要通过主内存来完成，

下面是 Java 内存模型下一些“天然的”先行发生关系，这些先行发生关系无须任何同步器协助就已经存在，可以在编码中直接使用。如果两个操作之间的关系不在此列，并且无法从下列规则推导出来，则它们就没有顺序性保障，虚拟机可以对它们随意地进行重排序。

- 程序次序规则（ProgramOrderRule）：在一个线程内，按照控制流顺序，书写在前面的操作先行发生于书写在后面的操作。注意，这里说的是控制流顺序而不是程序代码顺序，因为要考虑分支、循环等结构。

- 管程锁定规则（MonitorLockRule）：一个 unlock 操作先行发生于后面对同一个锁的 lock 操作。这里必须强调的是“同一个锁”，而“后面”是指时间上的先后。

- volatile 变量规则（VolatileVariableRule）：对一个 volatile 变量的写操作先行发生于后面对这个变量的读操作，这里的“后面”同样是指时间上的先后。
- 线程启动规则（ThreadStartRule）：Thread 对象的 start()方法先行发生于此线程的每一个动作。

- 线程终止规则（ThreadTerminationRule）：线程中的所有操作都先行发生于对此线程的终止检测，我们可以通过 Thread::join()方法是否结束、Thread::isAlive()的返回值等手段检测线程是否已经终止执行。

- 线程中断规则（ThreadInterruptionRule）：对线程 interrupt()方法的调用先行发生于被中断线程的代码检测到中断事件的发生，可以通过 Thread::interrupted()方法检测到是否有中断发生。

- 对象终结规则（FinalizerRule）：一个对象的初始化完成（构造函数执行结束）先行发生于它的 finalize()方法的开始。
- 传递性（Transitivity）：如果操作 A 先行发生于操作 B，操作 B 先行发生于操作 C，那就可以得出操作 A 先行发生于操作 C 的结论。

## 线程的实现

实现线程主要有三种方式：使用内核线程实现（1：1 实现），使用用户线程实现（1：N 实现），使用用户线程加轻量级进程混合实现（N：M 实现）。

## Java 线程的实现

以 HotSpot 为例，它的每一个 Java 线程都是直接映射到一个操作系统原生线程来实现的，而且中间没有额外的间接结构，
所以 HotSpot 自己是不会去干涉线程调度的（可以设置线程优先级给操作系统提供调度建议），
全权交给底下的操作系统去处理，所以何时冻结或唤醒线程、该给线程分配多少处理器执行时间、
该把线程安排给哪个处理器核心去执行等，都是由操作系统完成的，也都是由操作系统全权决定的。

## Java 线程调度

## 状态转换
