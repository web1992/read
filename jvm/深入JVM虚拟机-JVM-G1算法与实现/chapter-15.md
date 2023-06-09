# 第 15 章　GC 线程（并发篇）

- ConcurrentGCThread 类
- SuspendibleThreadSet 类
- join()：将当前线程加入集合内
- leave()：让当前线程退出集合
- suspend_all()：要求集合内的所有线程暂停 
- resume_all()：要求集合内的所有线程恢复
- should_yield()：集合是否接收到了暂停全部线程的请求 
- yield()：如果整个集合都被要求暂停，那么暂停当前线程
- 安全点
- SafepointSynchronize::begin
- SafepointSynchronize::end
- VMThread类
- VM_Operation


## ConcurrentGCThread

并发 GC 是用继承自ConcurrentGCThread类的子类实现的

## 安全点

安全点是指在程序运行过程中可以毫无矛盾地枚举所有根的状态。根是在进行标记或复制等操作时追溯对象指针时的起点部分。因此，如果无法满足“毫无矛盾地枚举”和“枚举所有根”两个条件，就有可能漏掉存活对象。

要想毫无矛盾地枚举根，最简单的方法是禁止在枚举过程中改变根。就这一点而言，暂停 mutator 等会改变根的线程是最简单的方法。因此，HotSpotVM 中的安全点是暂停所有 Java 线程

但并不是简单地暂停所有 Java 线程。在暂停线程之前，必须将属于自己的根放到 GC 能看见的位置。否则，GC 就无法找到所有的根。

JIT 编译器就是一个具体的例子。JIT 编译器在编译方法时会创建一个称为“栈图”（stack map）的东西。栈图表示栈和寄存器的哪个部分是指向对象的引用。于是，GC 就可以参考栈图来枚举根。由于维护创建出的栈图会消耗一些存储容量，所以 JIT 编译器只会在特定的时机生成栈图。因此，作为安全点，暂停线程的时机必须是维护栈图的时机。关于栈图，我们将在 13.1.9 节中详细讲解。

简单来说，安全点就是 mutator 的所有线程安全暂停的状态。这里所说的“安全暂停的状态”就是“可以安全地枚举根的状态”的意思

转移专用记忆集合维护线程也是与mutator 并发执行的线程，转移专用记忆集合线程集合也会被当作根使用。也就是说，即使是这些并发 GC 线程，也需要先将根放在 GC 看得见的地方之后再暂停执行。

## VMThread

VM 线程是用VMThread类定义的线程

```c++
//share/vm/runtime/vmThread.hpp
101: class VMThread: public NamedThread {    
// 执行VM操作
128:   static void execute(VM_Operation* op);
}
```

VM 线程内部有一个接收 VM 操作的队列。其他线程以 VM 操作为参数调用第 128 行代码中的execute()静态成员函数，由此将 VM 操作添加到内部队列中。VM 线程在检测到队列中新添加的 VM 操作后，就会执行 VM 操作的处理

## VM 操作 VM_Operation

典型的 VM 操作有获取栈跟踪、结束 VM 和获取 VM 堆的转储（dump）。与 GC 关系最紧密的操作，是必须要通过所谓的 Stop-the-World 机制来进行的暂停处理。在 G1GC 中，转移和并发标记的暂停处理都是作为 VM 操作交由 VM 线程执行的。此外，在 Java 中显式地执行完全 GC 时也是暂停处理，因此它也是作为 VM 操作由 VM 线程执行的。

几乎所有的 VM 操作都需要在安全点执行。因此在 VM 操作被执行时，VM 线程一般会调用SafepointSynchronize::begin()来进入安全点状态。

```c++
// share/vm/runtime/vm_operations.hpp
98: class VM_Operation: public CHeapObj {
// VM线程调用的方法
135:   void evaluate();
144:   virtual void doit()                       = 0;
145:   virtual bool doit_prologue()              { return true; };
146:   virtual void doit_epilogue()              {};
}
```

