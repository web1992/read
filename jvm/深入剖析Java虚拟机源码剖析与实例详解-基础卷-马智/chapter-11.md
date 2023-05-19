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
- 动态调整年龄阈值
- ageTable
- -XX:TargetSurvivorRatio
- 标记普通的根对象
- GenRemSet
- 转发指针
- markOop
- 卡表

## Serial收集器

Serial收集器是一个单线程的收集器，采用“复制”算法。“单线程”并不是说只使用一个CPU或一条收集线程去完成垃圾收集工作，而是指在进行垃圾收集时，必须暂停其他的工作线程，直到收集结束

## 回收过程

- 标记普通的根对象
- 标记老年代引用的对象
- 递归标记活跃对象并复制

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


## 年轻代的垃圾回收

- 当触发YGC时会产生一个VM_GenCollectForAllocation类型的任务

## DefNewGeneration

年轻代对象的实现类：DefNewGeneration，包含了eden, from and to-space 三部分，下面是源码。

```c++
// jdk8u/hotspot/src/share/vm/memory/defNewGeneration.hpp

// DefNewGeneration is a young generation containing eden, from- and
// to-space.

class DefNewGeneration: public Generation {
  friend class VMStructs;

}
```

## TenuredGeneration

`TenuredGeneration`是老年代对象的实现类。下面是源码地址

```c++
// jdk8u/hotspot/src/share/vm/memory/tenuredGeneration.hpp

// TenuredGeneration models the heap containing old (promoted/tenured) objects.
// ...
class TenuredGeneration: public OneContigSpaceCardGeneration {
  friend class VMStructs;
  // ...
}
```

## GC 回收的过程

1. GC开始之前先找到需要回收的内存区域：老年代/年轻代，如果是YGC 只回收年轻代，FGC 会回收年轻代+老年代
2. 年轻代用 DefNewGeneration 对象表示
3. 老年代用 TenuredGeneration 对象表示
4. 在确定需要回收的内存区域之和开始进行回收前的准备工作
5. 调用 GenCollectedHeap::save_marks()函数执行垃圾回收前的准备工作
6. 其他准备参考下面的 [GC准备工作] 
7. gen_process_strong_roots 复制移动对象
8. 当YGC执行成功，清空Eden和From Survivor空间并交换From Survivor和To Survivor空间的角色后，下一步是调整年轻代活跃对象的晋升阈值
9. 

## save_marks

```c++
// save_marks 方法是执行GC前的准备工作
void DefNewGeneration::save_marks() {
  eden()->set_saved_mark();
  to()->set_saved_mark();
  from()->set_saved_mark();
}
```

> _saved_mark_word

![saved-mark.drawio.svg](./images/saved-mark.drawio.svg)

_saved_mark_word和_top等变量会辅助复制算法完成年轻代的垃圾回收。


## 分配担保

- promotion_attempt_is_safe

```c++
// jdk8u/hotspot/src/share/vm/memory/tenuredGeneration.cpp
bool TenuredGeneration::promotion_attempt_is_safe(size_t max_promotion_in_bytes) const {
  size_t available = max_contiguous_available();
  size_t av_promo  = (size_t)gc_stats()->avg_promoted()->padded_average();
  bool   res = (available >= av_promo) || (available >= max_promotion_in_bytes);
  // ...
  return res;
}
```

根据之前的GC数据获取平均的晋升空间，优先判断可用空间是否大于等于这个平均的晋升空间，其次判断是否大于等于最大的晋升空间max_promotion_in_bytes，只要有一个条件为真，函数就会返回true，表示这是一次安全的GC。对于满足可用空间大于等于平均晋升空间这个条件来说，函数返回true后，YGC在执行过程中可能会遇到分配担保失败的情况，因为实际的晋升空间如果大于平均晋升空间时就会失败，此时就需要执行FGC操作了。


## GC准备工作

在开始回收对象之前还要做GC准备工作，具体如下：

- 初始化IsAliveClosure闭包，该闭包封装了判断对象是否存活的逻辑；
- 初始化ScanWeakRefClosure闭包，该闭包封装了扫描弱引用的逻辑，这里暂时不介绍；
- 清空ageTable数据和To Survivor空间，ageTable会辅助判断对象晋升的条件，而保证To Survivor空间为空是执行复制算法的必备条件；
- 初始化FastScanClosure，此闭包封装了存活对象的标识和复制逻辑。


## 年轻代到老年代的晋升过程的判断如下：

1. 长期存活的对象进入老年代

虚拟机给每个对象定义了一个对象年龄计数器。如果对象在Eden空间分配并经过第一次YGC后仍然存活，在将对象移动到To Survivor空间后对象年龄会设置为1。对象在Survivor空间每熬过一次，YGC年龄就加一岁，当它的年龄增加到一定程度（默认为15岁）时，就会晋升到老年代中。对象晋升老年代的年龄阈值，可以通过-XX:MaxTenuring-Threshold选项来设置。ageTable类中定义table_size数组的大小为16，由于通过-XX:MaxTenuringThreshold选项可设置的最大年龄为15，所以数组的大小需要设置为16，因为还需要通过sizes[0]表示一次都未移动的对象，不过实际上不会统计sizes[0]，因为sizes[0]的值一直为0。

2. 动态对象年龄判定

为了能更好地适应不同程度的内存状况，虚拟机并不总是要求对象的年龄必须达到MaxTenuringThreshold才能晋升到老年代。如果在Survivor空间中小于等于某个年龄的所有对象空间的总和大于Survivor空间的一半，年龄大于或等于该年龄的对象就可以直接进入老年代，无须等到MaxTenuringThreshold中要求的年龄。因此需要通过sizes数组统计年轻代中各个年龄对象的总空间。

## 动态调整年龄阈值

-XX:TargetSurvivorRatio选项表示To Survivor空间占用百分比。调用adjust_desired_tenuring_threshold()函数是在YGC执行成功后，所以此次年轻代垃圾回收后所有的存活对象都被移动到了To Survivor空间内。如果To Survivor空间内的活跃对象的占比较高，会使下一次YGC时To Survivor空间轻易地被活跃对象占满，导致各种年龄代的对象晋升到老年代。为了解决这个问题，每次成功执行YGC后需要动态调整年龄阈值，这个年龄阈值既可以保证To Survivor空间占比不过高，也能保证晋升到老年代的对象都是达到了这个年龄阈值的对象。

## swap_spaces
```c++
// openjdk/hotspot/src/share/vm/memory/defNewGeneration.cpp
void DefNewGeneration::swap_spaces() {
  // 简单交换From Survivor和To Survivor空间的首地址即可
  ContiguousSpace* s = from();
  _from_space       = to();
  _to_space         = s;

  // Eden空间的下一个压缩空间为From Survivor，FGC在压缩年轻代时通常会压缩这两个
  // 空间。如果YGC晋升失败，则From Survivor的下一个压缩空间是To Survivor，因此
  // FGC会压缩整理这三个空间
  eden()->set_next_compaction_space(from());
  from()->set_next_compaction_space(NULL);
}
```

## 标记普通的根对象

- FastScanClosure
- FastEvacuateFollowersClosure
