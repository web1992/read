# 第 12 章　HotSpotVM 的线程管理

- POSIX 线程标准
- Pthreads 库
- Thread 类
- CHeapObj类
- OSThread 类
- pthread_t
- ThreadStaet
- 警戒缓存
- Java 线程的警戒缓存


## Thread

![hotspot-thread.drawio.svg](./images/hotspot-thread.drawio.svg)

Thread类的父类ThreadShadow会对线程运行中发生的异常进行统一处理。

Thread类的子类JavaThread表示的是在 Java 语言级别运行的线程。当开发者创建一个 Java 线程时，HotSpotVM 内部就会创建一个JavaThread类的实例。不过JavaThread类和 GC 没有什么紧密关系，因此本书不会详细讲解它。

NameThread类支持线程的命名。我们可以为NameThread类及其子类的实例设置一个唯一的名字。那些被用作 GC 线程的类都是通过继承NameThread类而实现的。

## 线程的生命周期

让我们按照顺序来看一看线程是如何被创建出来，处理是如何开始和结束的。下面是一个线程的生命周期。

- ①创建Thread类的实例
- ②创建线程（os::create_thread()）
- ③开始线程处理（os::start_thread()）
- ④结束线程处理
- ⑤释放Thread类的实例

## ThreadState

```c++
// share/vm/runtime/osThread.hpp
44: enum ThreadState {
45:   ALLOCATED,    // 已经分配但还未初始化的状态
46:   INITIALIZED,  // 已经初始化但处理还未开始的状态
47:   RUNNABLE,     // 处理已经开始，可以启动的状态
48:   MONITOR_WAIT, // 等待监视器锁争用
49:   CONDVAR_WAIT, // 等待条件变量
50:   OBJECT_WAIT,  // 等待Object.wait()的调用
51:   BREAKPOINTED, // 停止在断点处
52:   SLEEPING,     // Thread.sleep()中
53:   ZOMBIE        // 虽满足条件，但还未回收的状态
54: };
```

## 警戒缓存

在可用于栈内存的内存空间底部有一块警戒缓存，访问操作系统的警戒缓存就等于栈内存溢出了。

Java 线程在可以用作栈内存的空间底部有一块自己的警戒缓存。

