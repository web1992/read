# 第11章 Serial垃圾收集器

- MarkSweepPolicy
- 内存不足触发GC
- GC 可能是YGC 或者是FGC
- 新生代用DefNewGeneration实例表示，老年代用TenuredGeneration实例表示
- -XX:+UseSerialGC
- _saved_mark_word
- 分配担保失败

## 触发YGC

大多数情况下，对象直接在年轻代中的Eden空间进行分配，如果Eden区域没有足够的空间，那么就会触发YGC（Minor GC，年轻代垃圾回收），YGC处理的区域只有年轻代。下面结合年轻代对象的内存分配看一下触发YGC的时机：

（1）新对象会先尝试在栈上分配，如果不行则尝试在TLAB中分配，否则再看是否满足大对象条件可以在老年代分配，最后才考虑在Eden区申请空间。

（2）如果Eden区没有合适的空间，则HotSpot VM在进行YGC之前会判断老年代最大的可用连续空间是否大于新生代的所有对象的总空间，具体判断流程如下：

① 如果大于的话，直接执行YGC。

② 如果小于，则判断是否开启了HandlePromotionFailure，如果没有开启则直接执行FGC。

③ 如果开启了HandlePromotionFailure，HotSpot VM会判断老年代的最大连续内存空间是否大于历次晋升的平均内存空间（晋级老年代对象的平均内存空间），如果小于则直接执行FGC；如果大于，则执行YGC。

对于HandlePromotionFailure，我们可以这样理解，在发生YGC之前，虚拟机会先检查老年代的最大的连续内存空间是否大于新生代的所有对象的总空间，如果这个条件成立，则YGC是安全的。如果不成立，虚拟机会查看HandlePromotionFailure设置值是否允许判断失败，如果允许，那么会继续检查老年代最大可用的连续内存空间是否大于历次晋级到老年代对象的平均内存空间，如果大于就尝试一次YGC，如果小于，或者Handle-PromotionFailure不愿承担风险就要进行一次FGC。