# 第9章 类对象的创建

- 对象的创建、引用和回收过程
- 在堆中分配内存
- 在TLAB中分配内存
- HeapWord
- 无锁式分配
- 全局锁式分配
- TemplateTable::_new
- bcp （byte code pointer）
- TLAB （Thread Local Allocation Buffer） 线程本地分配缓冲区
- VMThread
- 偏移表
- 卡表
- 偏移表中存储的是卡页中最后一个对象的开始地址
- set_remainder_to_point_to_start 更新偏移表
- 对象（可能）跨一个或多个完整的卡页

## 对象的创建

Java对象创建的流程大概如下：
- 1）检查对象所属类是否已经被加载解析。
- 2）为对象分配内存空间。
- 3）将分配给对象的内存初始化为零值。
- 4）执行对象的<init>方法进行初始化。

## 偏移表

Serial收集器只会对年轻代进行回收，回收的第一步就是找到并标记所有的活跃对象，除了常见的根集引用外，老年代引用年轻代的对象也需要标记。为了避免对老年代进行全扫描，老年代划分为512字节大小的块（卡页），如果块中有对象含有对年轻代的引用，则对应的卡表字节将标记为脏。`卡表是一个字节的集合`，每个字节用来表示老年代的512字节区域中的所有对象是否持有新生代对象的引用。

如果某个512字节区域中有对象引用了年轻代对象，则需要扫描这个512字节区域，但是从哪个对象的首地址开始扫描需要结合偏移表中记录的信息。偏移表记录了上一个卡页中最后一个对象（此对象的首地址必须在上一个卡页中）到上一个卡页尾地址之间的距离。

![memory-offset-table.drawio.svg](./images/memory-offset-table.drawio.svg)


```c++
// 源代码位置：openjdk/hotspot/src/share/vm/memory/blockOffsetTable.hpp
void alloc_block(HeapWord* blk, size_t size) {
   alloc_block(blk, blk + size);
}

void alloc_block(HeapWord* blk_start, HeapWord* blk_end) {
    if (blk_end > _next_offset_threshold) {
       alloc_block_work(blk_start, blk_end);
    }
}
```

其中，_next_offset_threshold通常指向正在分配的内存页的尾地址边界，当blk_end大于这个边界值时，说明要进行跨页存储对象，此时需要对对象偏移表进行操作。如果当前对象跨页，那么这个对象就是正在分配的内存页的最后一个对象（对象首地址在此内存页中），需要在此内存页A的下一个内存页B对应的偏移表项中存储一个距离，这个距离就是最后一个对象首地址距离内存页A尾的距离，如图9-4所示