# 第四章 运行时数据区

- 堆:用来分配Java对象和数组的空间。
- 方法区:存储类元数据。
- 栈:线程栈。
- PC寄存器:存储执行指令的内存地址。
- 堆 一块内存区域，满足程序的内存分配请求
- 自动的内存管理
- 分代收集( generational collection )
- 新生代( Young Generation，常称为YoungGen),位于堆空间;
- 老年代(Old Generation，常称为OldGen)，位于堆空间;
- 永久代( Permanent Generation，常称为PermGen), 位于非堆空间。
- universe.hpp
- 私有区域 PC 寄存器和栈
- 常量池
- constantPoolOopDesc
- 常量池缓存: ConstantPoolCache
- kclassOop
- itable
- ToState
- CpCacheOop
- methodOop methodOopDesc
- 方法表
- ConstMethodOop
- PerfData
— PerfMemory (通过共享内存实现)
- PerfMemory是运行时记录JVM信息的载体 
- perfMemory.hpp
- jstat -J-Djstat.showUnsupported=true -snap $pid
- JVM Crash
- hs_err_pid<pid>.log
- 程序计数器(PC) 进程ID (pid) 和线程ID ( tid)
- 线程信息 P155
- JVM 状态
- not at a safepoint:正常执行状态
- at safepoint:所有的线程阻塞，等待VM完成专门的VM操作(VM operation)
- synchronizing:VM接到一个专门的VM操作请求，等待VM中所有线程阻塞
- 应用程序转储
- 线程转储
- 堆转储

## 内存区域划分

图4-1运行时数据区的职能划分

![4-1-内存区域划分.drawio.svg](./images/4-1-内存区域划分.drawio.svg)

堆与方法区是所有线程共享的公共区域。堆与方法区所占的内存空间，是由JVM负责管理的。在该区域内的内存分配是由HotSpot的内存管理模块维护的，而内存的释放工作则由垃圾收集器自动完成。

栈和PC是线程的私有区域，是线程执行程序的工作场所。每个线程都关联着唯一的栈和PC寄存器，并仅能使用属于自己的一份栈空间和PC寄存器来执行程序。在HotSpot虚拟机实现中，Java 栈与本地栈合二为一， 是在本地内存空间中分配的。

- 新生代( Young Generation，常称为YoungGen),位于堆空间;
- 老年代(Old Generation，常称为OldGen)，位于堆空间;
- 永久代( Permanent Generation，常称为PermGen), 位于非堆空间。

其中，新生代中又被划分为1个Eden区和2个幸存区(Survivor),其中-一个称为from区，另一个则称为to区。

## PC 寄存器和栈

除了像堆这样的共享空间以外，系统还为每个线程准备了独享空间: PC寄存器和栈。这部分内存空间是为线程的函数调用栈服务的。在JVM运行期间，每个线程的PC和栈都只能由所属线程独自支配。栈反映了`程序运行位置`的变化，而PC寄存器反映的是所`执行指令`的变化情况。

如果当前执行方法不是本地方法(native method)，那么PC寄存器就保存JVM正在执行的字节码指令的地址，如果当前方法是本地方法，那PC寄存器中的值是未定义的，这是因为本地方法的执行依赖硬件PC寄存器，其值是由操作系统来维护的，虚拟机实现的PC寄存器的对本地方法不会产生任何作用。

## JVM栈

每一个Java线程都有自己私有的Java虛拟机栈( Java Virtual Machine Stack,或称JVM栈)。这个栈与线程同时创建，用于存储栈帧。Java虚拟机栈的作用与传统语言(例如C语言)中的栈非常类似，用于存储方法执行中的局部变量、中间演算结果以及方法返回结果。当进入一个
方法时，在栈顶分配一个 数据区域;在退出时，撤销该数据区。由于栈的结构特点，对该区域的操作主要是出栈和入栈，并没有受到其他系统组件的影响，所以JVM规范允许栈帧在堆中分配，对栈内存空间的连续性也没有做具体的要求。

JVM规范允许Java虚拟机栈被实现成固定大小的，或者是根据运行状况动态地扩展和收缩。如果采用固定大小的Java虚拟机栈，那每一条线程的栈容量在线程创建时就应明确。JVM实现应当提供配置栈初始容量的方法。对于可以动态扩展和收缩Java虚拟机栈来说,还应当提供调节其最大、最小容量的手段。

## 方法区

- 常量池;
- 域;
- 方法数据;
- 方法和构造函数的字节码;
- 类、实例、接口初始化时用到的特殊方法。

方法区在虚拟机启动时创建。虚拟机规范对方法区实现的位置并没有明确要求,在HotSpot虚拟机实现中，方法区仅是逻辑上的独立区域，在物理上并没有独立于堆而存在，而是位于永久代中。此外，虚拟机规范对这个区域是否实现垃圾回收，以及编译代码采用何种管理方式也没有特别规定，这些都可以由JVM自由实现。在HotSpot实现中，垃圾收集器会收集此区域，回收过程主要关注对常量池的收集以及对类的卸载。

Java虚拟机规范允许方法区的容量是固定的或是动态扩展的，方法区在实际内存空间中是可以不连续的。但是要求JVM实现应当提供调节方法区初始容量的手段，对于可以动态扩展和收缩方法区来说，则应当提供调节其最大、最小容量的手段。

方法区可能发生如下异常情况:如果方法区的内存空间不能满足内存分配请求，那么JVM将抛出一个OutOfMemoryError异常。

## 纽带作用

P127 介绍了方法的调用过程(如果对class文件结构熟悉，和容易理解)

## 常量池 常量池缓存: ConstantPoolCache

常量池的作用类似于C语言中的符号表, Java利用常量池实现类加载和连接阶段对符号引用的定位。

常量池的出现，解决了JVM定位字段和方法的问题。它在不破坏指令集的简洁性的前提下，仅通过少量字节就能够定位到目标。但是，若每次字段或方法的访问都需要解析常量池项的话，将不可避免地会造成性能下降。

为解决这一问题，在HotSpot虚拟机中引入了常量池缓存机制，简称常量池Cache。常量池Cache为Java类和接口的字段与方法提供快速访问入口。
常量池缓存由一个数组组成，元素类型是常量池缓存项，每个缓存项表示类中引用的一个字段或方法。常量池缓存项有两种类型。

- 字段项:用来支持对类变量和对象的快速访问。
- 方法项:用来支持invoke系列的函数调用指令，为这些方法调用指令提供快速定位目标方法的能力

常量池缓存项`ConstantPoolCacheEntry`的结构


## methodOop

- _constMethod:方法只读数据。
- _constants: 常量池。
- _interpreter_invocation_count: 解释器调用次数。
- _access_flags:访问标识。
- _vtable_index: 表示该methodOop在vtable 表中的索引位置。vtable 表是函数分发机制中的术语，在8.7节中对vtable表有更详细的讲解。
- _method_size: 占用大小。
- _max_stack: 操作数栈最大元素个数。
- _max_locals: 局部变量最大元素个数。
- _size_of_parameters::参数块大小。
- _interpreter_throwout_count: 解释运行时以异常方式退出方法的次数。
- _invocation_counter 和 _backedge_counter: 计数器:统计方法或循环体的被调用次数,用做基于触发频率的优化。
- _compiled_invocation_count: 方法被调用的次数。
- _i2i_entry:解释器调用入口地址。
- _from_compiled_entry: 编译代码入口
- _code: 指向本地代码。

## 方法表 方法的解析 P138-P139

- 将符号引用转换成直接引用

JVM规范规定，指令anewarray、checkcast. getfield、 getstatic、 instanceof. invokedynamic、invokeinterface、invokespecial 、invokestatic 、invokevirtual 、ldc、 ldc_w、 multianewarray、new、putfield和putstatic将符号引用指向运行时常量池。当执行到上述指令时，需要对它的符号引用进行解析。

- invokedynamic
- 链接解析器(LinkResolver)

## 转储

虚拟机提供转储技术，能够将运行时刻的程序快照保存下来，为调试、分析或诊断提供数据支持。转储类型包括以下3种:

- 核心转储 (core dump) / (crash dump);
- 堆转储 (heap dump);
- 线程转储 (thread dump)

转储文件为我们对故障进行离线分析提供了可能。

核心转储(coredump),也称为崩溃转储(crashdump),是一个正在运行的进程内存快照。它可以在一个致命或未处理的错误(如:信号或系统异常)发生时由操作系统自动创建。另外，也可以通过系统提供的命令行工具强制创建。核心转储文件可供离线分析，往往能揭示进程崩溃的原因。

一般来说，核心转储文件并不包含进程的全部内存空间数据，如.text节(或代码)等内存页就没有包含进去，但是至少包含堆和栈信息。

- HSDB
- jstack对core dump的支持选项(参见第9章)
- Visual VM
