# 第8章 运行时数据区

- 栈空间
- 解释栈和编译栈
- 堆空间
- 直接内存
- 元数据(元空间)
- 每个类加载器都会在元空间得到自己的存储区域
- VirtualSpaceNode 单链表
- Node MetaChunk
- Metaspace类
- 类指针压缩空间（Compressed Class Pointer Space）
- UseCompressedClassPointers
- 元空间和类指针压缩空间
- Metaspace的分配器 根据猜测分配chunk块
- SpaceManager和ChunkManager管理
- SpaceManager用来管理每个类加载器正在使用的Metachunk块
- ChunkManager用来管理所有空闲的Metachunk块
- 寄生栈
- Klass类内存分配
- Metaspace::allocate
- 类加载器
- ClassLoaderData实例
- 类加载器的卸载
- 内存回收
- CollectedHeap、Generation与Space类
- Serial收集器
- DefNewGeneration
- SurvivorRatio
- Space类
- ConcurrentMarkSweepPolicy
- 分代策略+回收策略 GenCollectedHeap + MarkSweepPolicy
- os::reserve_memory() 
- anon_mmap()
- MemRegion表示一段连续的内存地址空间
- 复制算法
- 压缩-整理算法
- 虚方法表


![memory-layout.drawio.svg](./images/memory-layout.drawio.svg)


## 1. 栈空间

栈空间是线程私有的，主要包含三部分：程序计数器、Java虚拟机栈和本地方法栈。

- 1）程序计数器

程序计数器是线程私有的一块内存区域，各线程之间的程序计数器不会相互影响。程序计数器对于HotSpot VM的解释执行非常重要。解释器通过改变这个计数器的值来选取下一条需要执行的字节码指令，分支、循环、跳转、异常处理、线程恢复等功能都需要依赖这个计数器来完成。

在Linux内核的64位系统上，HotSpot VM约定`%r13`寄存器保存指向当前要执行的字节码指令的地址，如果要执行调用，那么下一条字节码指令的地址可能会保存在解释栈的栈中，也可能会保存在线程的私有变量中。程序计数器的生命周期随着线程的创建而创建，随着线程的结束而死亡。

- 2）Java虚拟机栈

对于HotSpot VM来说，Java栈`寄生`在本地C/C++栈中，因此在一个C/C++栈中可能既有C/C++栈，又有Java栈。Java栈可以分为`解释栈`和`编译栈`，而栈是由一个个栈帧组成的，每个栈帧中都拥有局部变量表和操作数栈等信息。

Java栈中保存的主要内容是栈帧，每次函数调用都会有一个对应的栈帧被压入Java栈，每次函数调用结束后都会有一个栈帧被弹出。Java方法有return字节码和抛出异常两种返回方式，不管哪种返回方式都会导致栈帧被弹出。

与程序计数器一样，Java虚拟机栈也是线程私有的，而且随着线程的创建而创建，随着线程的结束而死亡。

- 3） 本地方法栈

本地方法栈其实就是C/C++栈，某个线程在执行过程中可能会调用Java的native方法，也可能会调用HotSpot VM本身用C/C++语言编写的函数，不过这二者并没有本质区别，因为native方法最终还是由C/C++语言实现的。

本地方法栈同样随着线程的创建而创建，随着线程的结束而死亡。

## 2. 堆空间

Java堆是所有线程共享的一块内存区域，该区域会存放几乎所有的对象及数组，由于对象或数组会不断地创建和死亡，所以这是Java垃圾收集器收集的主要区域。

Java将堆空间划分为`年轻代堆空间`和`老年代堆空间`，这样就可以使用分代垃圾收集算法。后面的章节中会介绍最基础的单线程收集器Serial和Serial Old，其中Serial采用`复制算法`回收年轻代堆空间，而Serial Old采用`压缩-整理算法`回收老年代堆空间。

我们可以进一步细分年轻代堆空间，将其划分为Eden区、From Survivor区和To Survivor区。采用复制算法时，通常需要保存To Survivor区为空，这样Serial收集器会将Eden区和From Survivor区的活跃对象复制到To Survivor区，然后回收Eden区和From Survivor区中未被标记的死亡对象。

前面讲过对象的创建需要先分配内存。首先会在TLAB中分配，其实TLAB就是Eden区中的一块内存，只不过这块内存被划分给了特定的线程而已。如果TLAB区分配失败，通常会在Eden区中的非TLAB空间内再次分配，因此对象通常优先在Eden区中分配内存。

## 3. 直接内存

直接内存并不是Java虚拟机运行时数据区的一部分，也不是Java虚拟机规范中定义的内存区域。在OpenJDK 8中，元空间使用的就是直接内存。与之前OpenJDK版本使用永久代很大的不同是，如果不指定内存大小的话，随着更多类的创建，虚拟机会耗尽所有可用的系统内存。

另外，JDK 1.4中新加入的NIO类引入了一种基于通道（Channel）与缓存区（Buffer）的I/O方式，它可以使用Native函数库直接分配堆外内存，然后通过一个存储在Java堆中的DirectByteBuffer对象作为这块内存的引用进行操作。这样就能在一些场景中显著提高性能，因为这避免了在Java堆和Native堆之间来回复制数据。

本机直接内存的分配不会受到Java堆的限制，但既然是内存，就会受到本机总内存及处理器寻址空间的限制。

## 元空间

从OpenJDK 8开始，使用元空间（Metaspace）替换了之前版本中使用的永久代（PermGen）。永久代主要存放以下数据：

- 类的元数据信息，如常量池、方法等；
- 类的静态信息；
- 字符串驻留。

相关的数据已经被转移到元空间或堆中了，如字符串驻留和类的静态信息被转移到了堆中，而类的元数据信息被转移到了元空间中，因此前面介绍的保存类的元数据信息的Klass、Method、ConstMethod与ConstantPool等实例都是在元空间上分配内存。

Metaspace区域位于堆外，因此它的内存大小取决于系统内存而不是堆大小，我们可以指定`MaxMetaspaceSize`参数来限定它的最大内存。

Metaspace用来存放类的元数据信息，元数据信息用于记录一个Java类在JVM中的信息，包括以下几类信息：

- Klass结构：可以理解为类在HotSpot VM内部的对等表示。
- Method与ConstMethod：保存Java方法的相关信息，包括方法的字节码、局部变量表、异常表和参数信息等。
- ConstantPool：保存常量池信息。
- 注解：提供与程序有关的元数据信息，但是这些信息并不属于程序本身。
- 方法计数器：记录方法被执行的次数，用来辅助JIT决策。

除了以上最主要的5项信息外，还有一些占用内存比较小的元数据信息也存放在Metaspace里。

虽然每个Java类都关联了一个java.lang.Class对象，而且是一个保存在堆中的Java对象，但是类的元数据信息不是一个Java对象，它不在堆中而是在Metaspace中。

## 元空间和类指针压缩空间

元空间和类指针压缩空间的区别如下：

类指针压缩空间只包含类的元数据，如`InstanceKlass`和`ArrayKlass`，虚拟机仅在打开了`UseCompressedClassPointers`选项时才生效。为了提高性能，Java中的虚方法表也存放到这里。
元空间包含的是类里比较大的元数据，如方法、字节码和常量池等。

## 内存块的管理

Metachunk块通过SpaceManager和ChunkManager管理，SpaceManager用来管理每个类加载器正在使用的Metachunk块，而ChunkManager用来管理所有空闲的Metachunk块。

## ChunkManager

ChunkManager类管理着所有类加载器卸载后释放的内存块Metachunk。该类及重要属性的定义如下：

```c++
//源代码位置：openjdk/hotspot/src/share/vm/memory/metaspace.cpp

typedef class FreeList<Metachunk> ChunkList;

class ChunkManager:public CHeapObj<mtInternal> {

  //   空闲列表中含有以下4种尺寸的块：
  //   SpecializedChunk
  //   SmallChunk
  //   MediumChunk
  //   HumongousChunk
  ChunkList _free_chunks[NumberOfFreeLists];

  //   巨大的块通过字典来保存
  ChunkTreeDictionary _humongous_dictionary;
  ...
}
```

ChunkManager类中的_free_chunks属性类似于SpaceManager类中的_chunks_in_use属性，但是会通过Freelist管理Metachunk，并且不管理超大块，超大块由_humongous_dictionary管理。因为ChunkManager类管理的空闲块有频繁的查询请求，几乎每次内存分配都要先从这些空闲块开始查询、分配，所以组织了高效的查询数据结构。

> 这里体现了分类管理内存的思想（提高效率）。

## Metaspace实例

在分配元数据区时，首先要调用类加载器的metaspace_non_null()函数获取Metaspace实例，该函数的实现代码如下：

```c++
//源代码位置：openjdk/hotspot/src/share/vm/classfile/classLoaderData.cpp
Metaspace* ClassLoaderData::metaspace_non_null() {
  if (_metaspace == NULL) {
    MutexLockerEx ml(metaspace_lock(),  Mutex::_no_safepoint_check_flag);
    if (_metaspace != NULL) {
      return _metaspace;
    }
    if (this == the_null_class_loader_data()) {
      set_metaspace(new Metaspace(_metaspace_lock, Metaspace::BootMetaspaceType));
    } else if (is_anonymous()) {
      set_metaspace(new Metaspace(_metaspace_lock, Metaspace::AnonymousMetaspaceType));
    } else if (class_loader()->is_a(SystemDictionary::reflect_DelegatingClassLoader_klass())) {
      set_metaspace(new Metaspace(_metaspace_lock, Metaspace::ReflectionMetaspaceType));
    } else {
      set_metaspace(new Metaspace(_metaspace_lock, Metaspace::StandardMetaspaceType));
    }
  }
  return _metaspace;
}
```

每个类加载器都会对应一个ClassLoaderData实例，该实例负责初始化并销毁一个ClassLoader实例对应的Metaspace。类加载器共有4类，分别是根类加载器、反射类加载器、匿名类加载器和普通类加载器，其中反射类加载器和匿名类加载器比较少见，根类加载器在第3章中介绍过，其使用C++编写，其他的扩展类加载器、应用类加载器及自定义的加载器等都属于普通类加载器。每个加载器都会对应一个Metaspace实例，创建出的实例由ClassLoaderData类中定义的_metaspace属性保存，以便进行管理。

## CollectedHeap、Generation与Space类

CollectedHeap是内存堆管理器的抽象基类，如果是分代管理堆，那么每个代都是一个Generation实例。在代中还会划分不同的区间，比如对于采用复制算法回收年轻代的Serial收集器来说，年轻代划分为Eden空间、From Survivor空间和To Survivor空间，每个空间都可以用Space实例来表示。

1. 内存堆管理器基类CollectedHeap

CollectedHeap是一个抽象基类，表示一个Java堆，定义了各种垃圾收集器必须实现的公共接口，这些接口就是上层用来创建Java对象、分配TLAB、获取Java堆使用情况的统一API。

GenCollectedHeap是一种基于内存分代管理的内存堆管理器。它不仅负责Java对象的内存分配，而且负责垃圾对象的回收，也是Serial收集器使用的内存堆管理器。

![CollectedHeap.drawio.svg](./images/CollectedHeap.drawio.svg)

2. Generation类

Generation类在HotSpot VM中采用的是分代回收算法，在Serial收集器下可表示年轻代或老年代，Generation类的继承体系如图8-5所示。

![Generation.drawio.svg](./images/Generation.drawio.svg)

Serial收集器主要针对代表年轻代的DefNewGeneration类进行垃圾回收，Serial Old收集器主要针对代表老年代的TenuredGeneration类进行垃圾回收。下面简单介绍这几个类。

- Generation：公有结构，保存上次GC耗时、该代的内存起始地址和GC性能计数。
- DefNewGeneration：一种包含Eden、From survivor和To survivor的分代。
- CardGeneration：包含卡表（CardTable）的分代，由于年轻代在回收时需要标记出年轻代的存活对象，所以还需要以老年代为根进行标记。为了避免全量扫描，通过卡表来加快标记速度。
- OneContigSpaceCardGeneration：包含卡表的连续内存的分代。
- TenuredGeneration：可Mark-Compact（标记-压缩）的卡表代。

在JVM参数中有一个比较重要的参数SurvivorRatio，用于定义新生代中Eden空间和Survivor空间（From Survivor空间或To Survivor空间）的比例，默认为8。也就是说，Eden空间占新生代的8/10，From Survivor空间和To Survivor空间各占新生代的1/10。

## Java堆的回收策略

基于“标记-清除”思想的GC策略MarkSweepPolicy是串行GC（-XX:+UseSerialGC）的标配，目前只能用于基于内存分代管理的内存堆管理器（GenCollectedHeap）的GC策略。当然，GenCollectedHeap还有另外两种GC策略：

并行“标记-清除”GC策略（ConcurrentMarkSweepPolicy），也就是通常所说的CMS；
可自动调整各内存代大小的并行“标记-清除”GC策略（ASConcurrentMarkSweep-Policy）。
在使用Serial与Serial Old收集器时使用的策略就是MarkSweepPolicy。除了MarkSweepPolicy策略以外的其他策略暂不介绍。

`GenCollectedHeap`是基于内存分代管理的思想来管理整个HotSpot VM的内存堆的，而`MarkSweepPolicy`作为GenCollectedHeap的默认GC策略配置，它的初始化主要是检查、调整及确定各内存代的最大、最小及初始化容量。

MarkSweepPolicy的继承体系如图8-10所示。

![CollectorPolicy.drawio.svg](./images/CollectorPolicy.drawio.svg)

OpenJDK 8默认使用Parallel Scavenger与Parallel Old垃圾收集器，因此要配置-XX:+UseSerialGC选项来使用Serial收集器。配置了-XX:+UseSerialGC选项后，会使用Serial收集器与Serial Old收集器收集年轻代与老年代，此时堆及代的布局如图8-13所示。

![java-heap.drawio.svg](./images/java-heap.drawio.svg)

在使用Serial和Serial Old收集器时，年轻代用DefNewGeneration实例表示，老年代用TenuredGeneration实例表示