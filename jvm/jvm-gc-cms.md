# CMS

Concurrent Mark Sweep，CMS

关键字:


- 分代回收
- CMS 产生内存碎片，会导致 FULL GC (STW)
- 首先，CMS收集器对处理器资源非常敏感。会占用CPU资源
- 产生“浮动垃圾”（Floating Garbage）
- 并发失败（Concurrent Mode Failure）冻结用户线程的执行，临时启用Serial Old收集器来重新进行老年代的垃圾收集
- CMS是一款基于“标记-清除”,会产生内存碎片，需要FULL GC 进行垃圾回收
- 记忆集 Remembered Set
- 写屏障（write barrier） 维护记录集
- 记忆集维护`老年代`对象到`年轻代`的引用，因为老年代的对象不会迁移了
- 晋升 (Promotion)
- Card table：提升写屏障效率 (位图)
- forwarding 指针
- GC Mark 和业务线程在同时工作
- 三色抽象
- 提前晋升


## 概述

从下面几个方面去理解CMS回收。

- 内存布局
- 内存分配
- 内存回收
- 关键技术

## 内存布局

![jvm-gc-parallel-heap-layout.drawio.svg](./images/jvm-gc-parallel-heap-layout.drawio.svg)

## 内存分配

基于空闲链的内存分配

## 内存回收

垃圾回收的执行的步骤：

- 1）初始标记（CMS initial mark）
- 2）并发标记（CMS concurrent mark）
- 3）重新标记（CMS remark）
- 4）并发清除（CMS concurrent sweep）
- 5）最终清理阶段，清理垃圾回收所使用的资源。为下一次 GC 执行做准备

## 关键技术


- 写屏障维护夸代引用（伪代码）

```java
// obj 当前对象
// field 当前对象的字段
// value 引用的新对象
// rs = 记忆集 Remembered Set
void do_oop_store(Value obj, Value* field, Value value) {
    if (in_young_space(value) && in_old_space(obj) &&
        !rs.contains(obj)) {
      rs.add(obj);
    }
    *field = &value;
}
```

- 对象晋升 (Promotion)

```java
// obj 对象晋升
void promote(obj) {
  new_obj = allocate_and_copy_in_old(obj);
  obj.forwarding = new_obj;
  
  for (oop in oop_map(new_obj)) {
    if (in_young_space(oop)) {
      rs.add(new_obj);
      return;
    }
  }
}
```

在上面的代码里，我们先在老年代中分配一块空间，把待晋升对象复制到老年代。然后把新地址 new_obj 记录到原来对象的 forwarding 指针。
接着遍历从这个对象出发的所有引用，如果这个对象有引用年轻代对象，就把这个晋升后的对象添加到记录集中。

- Card table 位图

Hotspot 的分代垃圾回收将老年代空间的 512bytes 映射为一个 byte，当该 byte 置位，则代表这 512bytes 的堆空间中包含指向年轻代的引用；如果未置位，就代表不包含。这个 byte 其实就和位图中标记位的概念很相似，人们称它为 card。多个 card 组成的表就是 Card table。一个 card 对应 512 字节，压缩比达到五百分之一，Card table 的空间消耗还是可以接受的。

- GC Mark 和业务线程在同时工作


- 三色抽象

- 白色：还未搜索的对象；
- 灰色：已经搜索，但尚未扩展的对象；
- 黑色：已经搜索，也完成扩展的对象。

漏标，黑色对象引用白色对象，白色对象不会再被扩展，漏掉标记。如果被回收，就GG了

解决漏标，向前一步，白色变成灰色，加入待处理队列
解决漏标，向后异步，黑色对象变成灰色对象，
如果对象修改比较频繁，那么后退一步的方案会比前进一步的方案更好，因为它不会产生浮动垃圾

## 缺点

- 占用线程资源，不适合单CPU
- Concurrent Mode Failure
- Floating Garbage

## Links

- [https://docs.oracle.com/javase/9/gctuning/concurrent-mark-sweep-cms-collector.htm#JSGCT-GUID-FF8150AC-73D9-4780-91DD-148E63FA1BFF](https://docs.oracle.com/javase/9/gctuning/concurrent-mark-sweep-cms-collector.htm#JSGCT-GUID-FF8150AC-73D9-4780-91DD-148E63FA1BFF)