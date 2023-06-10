# 第 17 章　转移

- 转移执行的时机
- attempt_allocation_slow
- do_collection_pause_at_safepoint
- target_pause_time_ms
- ConcurrentG1RefineThread
- G1ConcRefineThreads
- 所有的新生代区域都会被选到回收集合中


## 执行步骤转

移过程大致分为以下 3 个步骤。

- ①选择回收集合
- ②根转移
- ③转移

步骤①是选择转移对象的区域，即根据并发标记阶段获取的信息选择回收集合。

步骤②是将回收集合内由根直接引用的对象，和被其他区域引用的对象都转移到空区域。

步骤③是以②中转移的对象为起点，转移它们的子对象。当这一步骤结束后，回收集合内的存活对象就全部转移完毕了。

此外，转移一定是在安全点上执行的。因此，所有的 mutator 在转移过程中都处于暂停的状态。