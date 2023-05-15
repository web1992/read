# 第11章 Serial垃圾收集器

- MarkSweepPolicy
- 内存不足触发GC
- GC 可能是YGC 或者是FGC
- 新生代用DefNewGeneration实例表示，老年代用TenuredGeneration实例表示
- Eden
- From sruvivor
- To survivor
- -XX:+UseSerialGC
- _saved_mark_word
- 分配担保失败
- 长期存活的对象进入老年代
- 动态对象年龄判定
- ageTable
- -XX:TargetSurvivorRatio
- 标记普通的根对象
- GenRemSet
- 转发指针
- markOop
- 卡表

## Serial收集器

Serial收集器是一个单线程的收集器，采用“复制”算法。“单线程”并不是说只使用一个CPU或一条收集线程去完成垃圾收集工作，而是指在进行垃圾收集时，必须暂停其他的工作线程，直到收集结束

## _saved_mark_word

![saved-mark.drawio.svg](./images/saved-mark.drawio.svg)

## Serial GC 分代

![Serial-layout.drawio.svg](./images/Serial-layout.drawio.svg)

## 触发YGC

大多数情况下，对象直接在年轻代中的Eden空间进行分配，如果Eden区域没有足够的空间，那么就会触发YGC（Minor GC，年轻代垃圾回收），YGC处理的区域只有年轻代。下面结合年轻代对象的内存分配看一下触发YGC的时机：

（1）新对象会先尝试在栈上分配，如果不行则尝试在TLAB中分配，否则再看是否满足大对象条件可以在老年代分配，最后才考虑在Eden区申请空间。

（2）如果Eden区没有合适的空间，则HotSpot VM在进行YGC之前会判断老年代最大的可用连续空间是否大于新生代的所有对象的总空间，具体判断流程如下：

① 如果大于的话，直接执行YGC。

② 如果小于，则判断是否开启了HandlePromotionFailure，如果没有开启则直接执行FGC。

③ 如果开启了HandlePromotionFailure，HotSpot VM会判断老年代的最大连续内存空间是否大于历次晋升的平均内存空间（晋级老年代对象的平均内存空间），如果小于则直接执行FGC；如果大于，则执行YGC。

对于HandlePromotionFailure，我们可以这样理解，在发生YGC之前，虚拟机会先检查老年代的最大的连续内存空间是否大于新生代的所有对象的总空间，如果这个条件成立，则YGC是安全的。如果不成立，虚拟机会查看HandlePromotionFailure设置值是否允许判断失败，如果允许，那么会继续检查老年代最大可用的连续内存空间是否大于历次晋级到老年代对象的平均内存空间，如果大于就尝试一次YGC，如果小于，或者Handle-PromotionFailure不愿承担风险就要进行一次FGC。

> 安全的GC必须同时满足下面两个条件：

survivor中的to区为空，只有这样才能执行YGC的复制算法进行垃圾回收；
下一个内存代有足够的内存容纳新生代的所有对象，因为年轻代需要老年代作为内存空间担保，如果老年代没有足够的内存空间作为担保，那么这次的YGC是不安全的

## 年轻代到老年代的晋升过程的判断如下：

1. 长期存活的对象进入老年代

虚拟机给每个对象定义了一个对象年龄计数器。如果对象在Eden空间分配并经过第一次YGC后仍然存活，在将对象移动到To Survivor空间后对象年龄会设置为1。对象在Survivor空间每熬过一次，YGC年龄就加一岁，当它的年龄增加到一定程度（默认为15岁）时，就会晋升到老年代中。对象晋升老年代的年龄阈值，可以通过-XX:MaxTenuring-Threshold选项来设置。ageTable类中定义table_size数组的大小为16，由于通过-XX:MaxTenuringThreshold选项可设置的最大年龄为15，所以数组的大小需要设置为16，因为还需要通过sizes[0]表示一次都未移动的对象，不过实际上不会统计sizes[0]，因为sizes[0]的值一直为0。

2. 动态对象年龄判定

为了能更好地适应不同程度的内存状况，虚拟机并不总是要求对象的年龄必须达到MaxTenuringThreshold才能晋升到老年代。如果在Survivor空间中小于等于某个年龄的所有对象空间的总和大于Survivor空间的一半，年龄大于或等于该年龄的对象就可以直接进入老年代，无须等到MaxTenuringThreshold中要求的年龄。因此需要通过sizes数组统计年轻代中各个年龄对象的总空间。

## -XX:TargetSurvivorRatio

-XX:TargetSurvivorRatio选项表示To Survivor空间占用百分比。调用adjust_desired_tenuring_threshold()函数是在YGC执行成功后，所以此次年轻代垃圾回收后所有的存活对象都被移动到了To Survivor空间内。如果To Survivor空间内的活跃对象的占比较高，会使下一次YGC时To Survivor空间轻易地被活跃对象占满，导致各种年龄代的对象晋升到老年代。为了解决这个问题，每次成功执行YGC后需要动态调整年龄阈值，这个年龄阈值既可以保证To Survivor空间占比不过高，也能保证晋升到老年代的对象都是达到了这个年龄阈值的对象。

## 遍历根集的函数

Universe::oops_do()：主要是将Universe::initialize_basic_type_mirrors()函数中创建基本类型的mirror的instanceOop实例（表示java.lang.Class对象）作为根遍历。

JNIHandles::oops_do()：遍历全局JNI句柄引用的oop。

Threads::possibly_parallel_oops_do()或Threads::oops_do()：这两个函数会遍历Java的解释栈和编译栈。Java线程在解释执行Java方法时，每个Java方法对应一个调用栈帧，这些栈桢的结构基本固定，栈帧中含有本地变量表。另外，在一些可定位的位置上还固定存储着一些对oop的引用（如监视器对象），垃圾收集器会遍历这些解释栈中引用的oop并进行处理。Java线程在编译执行Java方法时，编译执行的汇编代码是由编译器生成的，同一个方法在不同的编译级别下产生的汇编代码可能不一样，因此编译器生成的汇编代码会使用一个单独的OopMap记录栈帧中引用的oop，以保存汇编代码的CodeBlob通过OopMapSet保存的所有OopMap，可通过栈帧的基地址获取对应的OopMap，然后遍历编译栈中引用的所有oop。

ObjectSynchronizer::oops_do()：ObjectSynchronizer中维护的与监视器锁关联的oop。
FlatProfiler::oops_do()：遍历所有线程中的ThreadProfiler，在OpenJDK 9中已弃用FlatProfiler。
Management::oops_do()：MBean所持有的对象。
JvmtiExport::oops_do()：JVMTI导出的对象、断点或者对象分配事件收集器的相关对象。

SystemDictionary::oops_do()或SystemDictionary::always_strong_oops_do()：System Dictionary是系统字典，记录了所有加载的Klass，通过Klass名称和类加载器可以唯一确定一个Klass实例。
ClassLoaderDataGraph::oops_do()或ClassLoaderDataGraph::always_strong_oops_do()：每个ClassLoader实例都对应一个ClassLoaderData，后者保存了前者加载的所有Klass、加载过程中的依赖和常量池引用。可以通过ClassLoaderDataGraph遍历所有的ClassLoaderData实例。

StringTable::possibly_parallel_oops_do()或StringTable::oops_do()：StringTable用来支持字符串驻留。
CodeCache::scavenge_root_nmethods_do()或CodeCache::blobs_do()：CodeCache代码引用。