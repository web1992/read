# AQS

- [AQS](#aqs)
  - [AbstractQueuedSynchronizer](#abstractqueuedsynchronizer)
  - [实例分析](#%e5%ae%9e%e4%be%8b%e5%88%86%e6%9e%90)
  - [AbstractQueuedSynchronizer.Node](#abstractqueuedsynchronizernode)
  - [Node.waitStatus](#nodewaitstatus)
    - [CANCELLED](#cancelled)
    - [SIGNAL](#signal)
    - [PROPAGATE](#propagate)
  - [AbstractQueuedSynchronizer queue and state](#abstractqueuedsynchronizer-queue-and-state)
  - [参考](#%e5%8f%82%e8%80%83)

## AbstractQueuedSynchronizer

`java.util.concurrent.locks.AbstractQueuedSynchronizer`

1. `AbstractQueuedSynchronizer` 是一个模板抽象类,封装了算法细节,暴露了很多 `protected` 方法方便子类重写
2. `AbstractQueuedSynchronizer` 是基于 `FIFO` 队列实现的
3. `AbstractQueuedSynchronizer` 中使用 `volatile int state` 来`计数`
4. `AbstractQueuedSynchronizer` 可以实现可以重入锁(或者不可重入锁)的语义，如 `ReentrantLock`
5. `AbstractQueuedSynchronizer` 可以实现共享锁，排他锁的语义，如 `ReentrantReadWriteLock`
6. `AbstractQueuedSynchronizer` 可以实现公平锁，非公平锁的语义

## 实例分析

- [count-down-latch.md](count-down-latch.md)
- [reentrant-lock.md](reentrant-lock.md)

## AbstractQueuedSynchronizer.Node

```java
// Node 的定义
static final class Node {
 static final Node SHARED = new Node();
 static final Node EXCLUSIVE = null;
 static final int CANCELLED =  1;
 static final int SIGNAL    = -1;
 static final int CONDITION = -2;
 static final int PROPAGATE = -3;
 volatile int waitStatus;
 volatile Node prev;
 volatile Node next;
 volatile Thread thread;
 Node nextWaiter;
}
```

## Node.waitStatus

```java
// Node
// waitStatus 是 Node 的成员变量
volatile int waitStatus;
```

```java
/** waitStatus value to indicate thread has cancelled */
static final int CANCELLED =  1;
/** waitStatus value to indicate successor's thread needs unparking */
static final int SIGNAL    = -1;
/** waitStatus value to indicate thread is waiting on condition */
static final int CONDITION = -2;
/**
 * waitStatus value to indicate the next acquireShared should
 * unconditionally propagate
 */
static final int PROPAGATE = -3;
```

### CANCELLED

线程获取锁失败，比如：线程执行了 `interrupt` 方法,或者获取锁超时，此时正在阻塞的线程就会被唤醒，进入 `CANCELLED` 状态

可以参考 `AbstractQueuedSynchronizer` 的 `cancelAcquire` 方法

### SIGNAL

当执行线程获取锁失败（比如`reentrantLock.lock()`），线程会进入 `SIGNAL` 状态

类似的 `CountDownLatch.await` 其实也是获取锁的过程，获取锁失败，也会进入到 `SIGNAL` 状态

### PROPAGATE

TODO

## AbstractQueuedSynchronizer queue and state

AbstractQueuedSynchronizer 最重要的几个变量

`Node head` 和 `Node tail` 用来组成 FIFO queue

`int state` 变量用来对获取锁的线程计数

此外它们都是用 `volatile` 来修饰的

```java
/**
 * Head of the wait queue, lazily initialized.  Except for
 * initialization, it is modified only via method setHead.  Note:
 * If head exists, its waitStatus is guaranteed not to be
 * CANCELLED.
 */
private transient volatile Node head;
/**
 * Tail of the wait queue, lazily initialized.  Modified only via
 * method enq to add new wait node.
 */
private transient volatile Node tail;
/**
 * The synchronization state.
 */
private volatile int state;
```

## 参考

- [cas and aqs (csdn)](https://blog.csdn.net/u010862794/article/details/72892300)
- [aqs (github)](<https://github.com/CL0610/Java-concurrency/blob/master/08.%E5%88%9D%E8%AF%86Lock%E4%B8%8EAbstractQueuedSynchronizer(AQS)/%E5%88%9D%E8%AF%86Lock%E4%B8%8EAbstractQueuedSynchronizer(AQS).md>)
- [aqs (简书)](https://www.jianshu.com/p/cc308d82cc71)
- [aqs](https://wyj.shiwuliang.com/JAVA%20-%20AQS%E6%BA%90%E7%A0%81%E8%A7%A3%E8%AF%BB.html)
