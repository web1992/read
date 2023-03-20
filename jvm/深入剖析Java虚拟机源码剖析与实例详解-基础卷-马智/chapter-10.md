# 第10章 垃圾回收

- 转发指针
- Serial收集器
- 卡表 Card Table
- 卡页（Card Page）
- GenRemSet 记忆集
- 屏障
- 偏移表
- 垃圾回收线程 VMThread
- VM_operation
- VMOperationQueue
- os::create_thread()
- pthread的ID

OpenJDK 8版本中的垃圾收集器都采用了分代垃圾回收机制，根据对象存活周期的不同将内存划分为几个内存代并采用不用的垃圾收集算法进行回收。

一般把Java堆分为新生代和老年代，这样就可以根据各个分代的特点采用最适当的收集算法。在新生代中，如果每次垃圾收集时发现有大批对象死去，只有少量存活，那就选用复制算法，只需要付出少量存活对象的复制成本就可以完成垃圾收集。老年代中因为对象存活率高，没有额外的空间对它分配担保，必须使用“标记-清除”和“标记-整理”算法进行回收。

本节只介绍Serial和Serial Old垃圾收集器。Serial垃圾收集器回收年轻代空间，采用的是复制算法，老年代使用的是Serial Old垃圾收集器，采用的是“标记-整理”算法。

![chapter-03-6.drawio.svg](./images/chapter-03-6.drawio.svg)

## Serial收集器

1. Serial收集器（串行收集器）

Serial收集器是一个单线程的收集器，采用“复制”算法。单线程的意义一方面指它只会使用一个CPU或一条收集线程去完成垃圾收集工作，另一方面指在进行垃圾收集时必须暂停其他的工作线程，直到收集结束。

> Serial收集器只负责年轻代的垃圾回收，触发YGC时一般都是由此收集器负责垃圾回收。

2. Serial Old收集器

Serial Old收集器也是一个单线程收集器，使用“标记-整理”算法。当使用Serial Old进行垃圾收集时必须暂停其他的工作线程，直到收集结束。

> Serial Old收集器不但会回收老年代的内存垃圾，也会回收年轻代的内存垃圾，因此一般触发FGC时都是由此收集器负责回收的。

## 常用的垃圾回收算法有以下4种：

- 复制算法；
- “标记-整理”算法；
- “标记-清除”算法；
- 分代收集算法。

HotSpot VM中的所有垃圾收集器采用的都是分代收集算法，针对年轻代通常采用的是复制算法，老年代可以采用“标记-清除”或“标记-整理”算法。Serial收集器采用的是复制算法，而Serial Old收集器采用的是“标记-整理”算法。

## 复制算法

最简单的复制（Copying）算法就是将可用内存按容量划分为大小相等的两块，每次只使用其中的一块。当这一块内存用完后，将活的对象标记出来，然后把这些活对象复制到另外一块空闲区域上，最后再把已使用过的内存空间完全清理掉。这样每次都是对整个半区进行内存回收，内存分配时也不用考虑内存碎片等复杂情况，只要移动堆顶指针，按顺序分配内存即可，实现方法简单，运行高效。但是这种算法的代价是将内存缩小了一半。

由于系统中大部分对象的生命周期非常短暂，所以并不需要按照1:1的比例来划分内存空间，而是将内存分为一块较大的Eden空间和两块较小的Survivor空间（即From Survivor空间和To Survivor空间），每次使用Eden和From Survivor空间。当回收时，将Eden和From Survivor空间中还存活的对象一次性地复制到To Survivor空间，最后清理Eden和From Survivor空间。HotSpot VM默认Eden:Survivor为8:1，也就是每次新生代中可用内存空间为整个新生代容量的90%（其中一块Survivor不可用），只有10%的内存会被“浪费”。

当然，大部分的对象可回收只是针对一般场景中的数据而言的，我们没有办法保证每次回收时只有不多于10%的对象存活，当To Survivor空间不够用时，需要依赖其他内存（这里指老年代）进行分配担保（Handle Promotion）。

## “标记-整理”算法

复制算法在对象存活率较高时需要进行较多的复制操作，效率将会变低，更关键的是如果不想浪费过多的内存空间，就需要有额外的空间进行分配担保，以应对被使用的内存中对象存活过多的情况，因此老年代一般不能直接选用复制算法。

老年代中一般是一些生命周期较长的对象，Serial Old收集器采用“标记-整理”（Mark-Compact）算法进行回收，标记过程与“标记-清除”算法一样，但后续步骤不是直接对可回收对象进行清理，而是让所有存活的对象都向一端移动，然后直接清理端边界以外的内存，这样能够避免产生更多的内存碎片。在分配内存时可直接移动堆顶指针，按顺序分配内存，同时也容易为大对象找到可分配的内存，但复制会降低内存回收效率。

- 1）初始引用状态。
- 2）标记活跃对象。
- 3）计算压缩-整理后的地址
- 4）复制对象到新的地址。

## 卡表

为了支持高频率的新生代回收，HotSpot VM使用了一种叫作卡表（Card Table）的数据结构。卡表是一个字节的集合，每一个字节可以用来表示老年代某一区域中的所有对象是否持有新生代对象的引用。我们可以根据卡表将堆空间划分为一系列2次幂大小的卡页（Card Page），卡表用于标记卡页的状态，`每个卡表项对应一个卡页`，HotSpot VM的卡页（Card Page）大小为512字节，卡表为一个简单的字节数组，即卡表的每个标记项为1个字节。

> 卡页 对堆空间的抽象(对堆内存的分组)，大小为512字节。

当老年代中的某个卡页持有了新生代对象的引用时，HotSpot VM就把这个卡页对应的卡表项标记为dirty。这样在进行YGC时，可以不用全量扫描所有老年代对象或不用全量标记所有活跃对象来确定对年轻代对象的引用关系，只需要扫描卡表项为dirty的对应卡页，而卡表项为非dirty的区域一定不包含对新生代的引用。这样可以提高扫描效率，减少YGC的停顿时间。

在实际应用中，仅靠卡表是无法完成具体扫描任务的，还需要与偏移表、屏障等配合才能更好地完成标记卡表项及扫描卡页中的对象等操作。

在实际情况中，当屏障判断出对象中的某个字段有对年轻代对象的引用时，会通过这个字段的地址addr找到卡表项，然后将卡表项标记为dirty。在执行YGC时，由于只回收年轻代，所以老年代引用的年轻代对象也需要标记，当然我们可以全量扫描老年代对象，找出所有引用的年轻代对象。为了提高效率，可以只扫描卡表项为dirty的卡页中的对象，然后扫描这些对象的引用域即可。

## BarrierSet

BarrierSet的功能类似于一个拦截器，在读写动作实际作用于内存前执行某些前置或者后置动作

## 偏移表

卡表只能粗粒度地表示某个对象中引用域地址所在的卡页，并不能通过卡表完成卡页中引用域的遍历，因此在实际情况下只能描述整个卡页中包含的对象，然后扫描对象中的引用域

在实际情况中，当屏障判断出对象中的某个字段有对年轻代对象的引用时，会通过这个字段的地址addr找到卡表项，然后将卡表项标记为dirty。在执行YGC时，由于只回收年轻代，所以老年代引用的年轻代对象也需要标记，当然我们可以全量扫描老年代对象，找出所有引用的年轻代对象。为了提高效率，可以只扫描卡表项为dirty的卡页中的对象，然后扫描这些对象的引用域即可。

为了确定某个脏卡页中第1个对象的开始位置，需要通过偏移表记录相关信息。

## VMThread

VMThread主要处理垃圾回收。如果是多线程回收，则启动多个线程回收；如果是单线程回收，使用VMThread回收。在VMThread类中定义了_vm_queue，它是一个队列，任何执行GC的操作都是VM_Operation的一个实例。用户线程JavaThread会通过执行VMThread::execute()函数把相关操作放到队列中，然后由VMThread在run()函数中轮询队列并获取任务，

```c++
// 源代码位置：openjdk/hotspot/src/share/vm/runtime/osThread.hpp
class OSThread: public CHeapObj<mtThread> {
 private:
  ...
  volatile ThreadState _state;
      public:
  pthread_t _pthread_id;
  ...
  private:
  Monitor* _startThread_lock;
}
Monitor* Notify_lock                  = NULL;
```

其中，_state指明了线程的状态；_pthread_id保存Linux线程pthread的ID，OSThread实例通过这个属性来管理pthread线程；_startThread_lock用来同步父子线程的状态，其中父线程就是创建OSThread实例的线程，而子线程就是由OSThread实例管理的pthread线程。

```c++
// 源代码位置：openjdk/hotspot/src/os/linux/vm/os_linux.cpp
bool os::create_thread(Thread* thread, ThreadType thr_type, size_t stack
_size) {

  // 创建一个OSThread实例
  OSThread* osthread = new OSThread(NULL, NULL);
  if (osthread == NULL) {
   return false;
  }

  // 设置当前线程的状态为os::vm_thread
  osthread->set_thread_type(thr_type);

  // 初始化状态为ALLOCATED
  osthread->set_state(ALLOCATED);

  // 使VMThread的osthread指针指向新建的OSThread实例
  thread->set_osthread(osthread);

  // 初始化线程相关属性
  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
  ...
  pthread_attr_setguardsize(&attr, os::Linux::default_guard_size(thr_type));

  ThreadState state;

  {
   ...
   // 传入了java_start()函数的指针
   pthread_t tid;
   // 创建并运行pthread子线程
   int ret = pthread_create(&tid, &attr, (void* (*)(void*)) java_start,thread);

   pthread_attr_destroy(&attr);

   // 这个tid是刚才新建的底层级线程的一个标识符，我们需要通过这个标识符来管理底层级
   // 线程
   osthread->set_pthread_id(tid);

   // 当前线程等待，直到创建的pthread子线程初始化完成或者退出
   {
     Monitor* sync_with_child = osthread->startThread_lock();
     MutexLockerEx ml(sync_with_child, Mutex::_no_safepoint_check_flag);
     while ((state = osthread->get_state()) == ALLOCATED) {
       sync_with_child->wait(Mutex::_no_safepoint_check_flag);
     }
   }
   ...
  }

  return true;
}
```

OSThread由JavaThread实例创建并进行管理。调用pthread_create()函数会启动操作系统的一个线程执行java_start()函数。VMThead、OSThread和pthead线程的关系如图10-23所示。

![vm-thread.drawio.svg](./images/vm-thread.drawio.svg)

thread_create()是UNIX、Linux、Mac等操作系统中的创建线程的函数，其功能是创建线程（实际上就是确定调用该线程函数的入口点），并且当线程创建以后，就开始运行相关的线程函数。pthread_create()函数的声明如下：

```c++
int pthread_create(
  pthread_t *restrict tidp,             // 新创建的线程ID指向的内存单元
  const pthread_attr_t *restrict attr,  // 线程属性，默认为NULL
  void *(*start_rtn)(void *),  // 新创建的线程从start_rtn函数的地址开始运行
  void *restrict arg           // 默认为NULL。若上述函数需要参数，将参数放入结
                               // 构中并将地址作为arg传入
);
```

run()函数中调用的`VMThread::loop()`函数的实现代码如下：

```c++
// 源代码位置：openjdk/hotspot/src/share/vm/runtime/vmThread.cpp
void VMThread::loop() {
  while(true) {
VM_Operation* safepoint_ops = NULL;

   // 1．线程获取任务，如果没有取到则等待
   // 2．线程执行任务
   ...
  } while循环结束
}
```


## Links

- [cardTableModRefBS.cpp](https://github.com/openjdk/jdk8u/blob/master/hotspot/src/share/vm/memory/cardTableModRefBS.cpp)