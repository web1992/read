# CMS

关键字:

- 分代回收
- CMS 产生内存碎片，会导致 FULL GC (STW)
- 首先，CMS收集器对处理器资源非常敏感。会占用CPU资源
- 产生“浮动垃圾”（Floating Garbage）
- 并发失败（Concurrent Mode Failure）冻结用户线程的执行，临时启用Serial Old收集器来重新进行老年代的垃圾收集
- CMS是一款基于“标记-清除”,会产生内存碎片，需要FULL GC 进行垃圾回收

## 概述

从下面几个方面去理解CMS回收。

- 内存布局
- 内存分配
- 内存回收
- 关键技术

## 内存布局

![jvm-gc-parallel-heap-layout.drawio.svg](./images/jvm-gc-parallel-heap-layout.drawio.svg)

## 内存分配

## 内存回收

垃圾回收的执行的步骤：

- 1）初始标记（CMS initial mark）
- 2）并发标记（CMS concurrent mark）
- 3）重新标记（CMS remark）
- 4）并发清除（CMS concurrent sweep）

## 关键技术

## 缺点

- 占用线程资源，不适合单CPU
- Concurrent Mode Failure
- Floating Garbage

## Links

- [https://docs.oracle.com/javase/9/gctuning/concurrent-mark-sweep-cms-collector.htm#JSGCT-GUID-FF8150AC-73D9-4780-91DD-148E63FA1BFF](https://docs.oracle.com/javase/9/gctuning/concurrent-mark-sweep-cms-collector.htm#JSGCT-GUID-FF8150AC-73D9-4780-91DD-148E63FA1BFF)