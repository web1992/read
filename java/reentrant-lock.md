# ReentrantLock

- [ReentrantLock](#reentrantlock)
  - [简介](#简介)
  - [Lock interface](#lock-interface)
  - [ReentrantLock.lock 的实现](#reentrantlocklock-的实现)
  - [AbstractQueuedSynchronizer.tryAcquire](#abstractqueuedsynchronizertryacquire)
    - [AbstractQueuedSynchronizer.acquire](#abstractqueuedsynchronizeracquire)
    - [AbstractQueuedSynchronizer.acquireQueued](#abstractqueuedsynchronizeracquirequeued)
  - [ReentrantLock.unlock 的实现](#reentrantlockunlock-的实现)
  - [tryRelease](#tryrelease)
  - [unparkSuccessor](#unparksuccessor)
  - [waitStatus](#waitstatus)
  - [公平锁&非公平锁的实现](#公平锁非公平锁的实现)
    - [NonfairSync](#nonfairsync)
    - [FairSync](#fairsync)
  - [demo](#demo)
  - [Link](#link)

## 简介

- `ReentrantLock` 提供了和 `synchronized` 同样的语义，但是扩展了 `synchronized`
- `ReentrantLock` 可以重入，同一个线程可以多次获取锁
- `ReentrantLock` 实现了 `公平锁` & `非公平锁` 的语义
- `ReentrantLock` 必须使用 `try`加锁，`finally` 来释放锁
- `ReentrantLock` 可以使用 `tryLock` 设置锁的超时时间
- `ReentrantLock` 能响应中断信号,`synchronized` 不会响应中断信号
- `ReentrantLock` 可以使用`newCondition`方法，等待在多个条件

## Lock interface

```java
// 这里看下 Lock接口的定义
// lock 用来获取锁
// unlock 用来释放锁
// Condition 负责线程的阻塞和唤醒
public interface Lock {
    void lock();
    void lockInterruptibly() throws InterruptedException;
    boolean tryLock();
    boolean tryLock(long time, TimeUnit unit) throws InterruptedException;
    void unlock();
    Condition newCondition();
}
```

下面我们从 `lock` 和 `unlock` 去分析实现过程

## ReentrantLock.lock 的实现

先看下 `ReentrantLock.lock` 方法的调用链

```java
ReentrantLock.lock -> ReentrantLock.Sync.lock
    -> compareAndSetState -> 成功 -> 结束
                        |
                        | -> 失败 -> acquire
                                 -> tryAcquire
                                 -> addWaiter
                                 -> acquireQueued
                                 -> tryAcquire -> 成功  -> setHead -> cancelAcquire -> 结束
                                                |
                                                |-> 失败  -> shouldParkAfterFailedAcquire
                                                         -> parkAndCheckInterrupt
                                                         -> cancelAcquire
                                                         -> 结束
```

上面的 `tryAcquire` 方法作用是修改(使用cas) `AbstractQueuedSynchronizer` 的 `state` 的状态

修改成功：说明竞争到了锁，那么该线程继续执行
修改失败：竞争锁失败，那么该线程执行下面的 `shouldParkAfterFailedAcquire` & `parkAndCheckInterrupt` 方法进入阻塞状态

对上面的方法调用链的分支，我这里把他们分为二类，方便理解

一类是修改 `state` 变量的操作

另一类是执行 `入队` 的操作

这也是 `AbstractQueuedSynchronizer` 的核心思路：**在线程之间去竞争获取锁的时候，先尝试修改 `state` 字段的值，如果修改成功，获取锁就是成功的，该线程继续执行，失败就把当前线程放入队列，阻塞当前线程，等他其他线程唤醒**

以公平锁为例，看下 `tryAcquire` 方法的实现（属于修改 `state` 这一类的操作）

## AbstractQueuedSynchronizer.tryAcquire

```java
protected final boolean tryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();// c=0 意味着没有线程获取锁
    if (c == 0) {
        // hasQueuedPredecessors 是判断是否有其他线程在排队，为了实现公平锁的语义
        // 下面尝试修改 state 的值，如果修改成功，那么代表获取锁成功
        if (!hasQueuedPredecessors() &&
            compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {
        // 不等于0，说明存在其他线程已经获取锁了，判断是不是同一个线程
        // 如果是，执行 state +1
        // 也就是可重入锁的实现
        // 如果之前获取锁的线程和当前线程是同一个
        // 就对 state +1
        // 这里 setState 直接设置，而没有使用 cas
        // 是因为当地线程已经获取锁了，其他线程不会修改 state 的值
        // 如果线程A执行了两次 lock 方法，那么必须执行两次 unlock
        // 线程A才会释放锁
        // 原因也很简单，执行了两次 lock 之后 state=2
        // 如果只执行一次 unlock ，此时state=1 ,不为 0
        // 其他线程是无法获取锁
        int nextc = c + acquires;
        if (nextc < 0)
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}
```

> 陷阱： 如果使用了`两次` `try` 获取锁，那么必须使用`两次` `unlock` 去释放锁，否则其他线程会获取不到锁

### AbstractQueuedSynchronizer.acquire

`acquire` 方法属于第二类操作(执行 `入队` 的操作)

```java
// AbstractQueuedSynchronizer
// 1.tryAcquire 尝试获取锁
//   如果获取锁失败，那么把当前线程进入队列（执行addWaiter）
// 2.addWaiter 把当前线程封装成 Node 放入队列
// 3.acquireQueued 阻塞当前线程
public final void acquire(int arg) {
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}
```

### AbstractQueuedSynchronizer.acquireQueued

`acquireQueued` 方法执行了 **修改 `state` 的操作** 和 **阻塞获取锁失败的线程的操作**

```java
// AbstractQueuedSynchronizer#acquireQueued
// 这个方法做了下面几件事：
// 1.获取锁
//   tryAcquire 是在 for(;;) 中执行的
//   当前线程在第一次调用 tryAcquire 时，获取锁失败，就会执行 parkAndCheckInterrupt
//   进入阻塞，当再次被唤醒时，再次调用 tryAcquire 获取锁,获取失败，再次进入阻塞
//   成功执行 return 结束循环
// 2.[获取锁成功] 修改 队列的 head
//    在执行 tryAcquire 成功之后，表示当前线程获取锁成功了
//    修改队列的 head 为当前线程（旧 head 出队列，当前线程变成 head）
// 3.[获取锁失败] 更新前一个 node 的 waitStatus = Node.SIGNAL
//   acquireQueued 方法是在 tryAcquire 执行失败之后执行的(获取锁失败)
//   然后通过 shouldParkAfterFailedAcquire 方法获取前一个node 的 waitStatus
//   如果不是 Node.SIGNAL 就更新为 Node.SIGNAL
// 4.[获取锁失败] 阻塞当前线程
//   parkAndCheckInterrupt 方法使用 LockSupport.park(this); 阻塞当前线程
final boolean acquireQueued(final Node node, int arg) {
    boolean failed = true;
    try {
        boolean interrupted = false;
        for (;;) {
            // 通过下面的 enq 可知，队列的 head 初始化之后，新的node 会在 head 后面
            // 由于并发的原因，新的node 不一定以后是紧挨着head 的，有下面两种情况：
            // head <- node 情况1：node 在head 后面
            // head <- nodeA <- node 情况2: node 不在head 后面，中间有 nodeA 存在
            final Node p = node.predecessor();// 获取当前node 的前一个元素
            if (p == head && tryAcquire(arg)) {// 与 head 对比，如果相等，说明 node 是队列中的第一个元素，尝试获取锁（也就是情况1）
                setHead(node);// 获取成功,修改head (这里并没有使用cas 去修改)
                p.next = null; // help GC
                failed = false;
                return interrupted;
            }
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())// 这里会阻塞（阻塞当前线程）
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}
// 修改 head
// 这里并没有使用 cas 去修改的原因是：
// 其他线线程在 tryAcquire 的时候失败了(在 ReentrantLock 的实现中就是修改 state 的值)
// 也就是获取锁失败，那么代码会继续执行 parkAndCheckInterrupt 方法，进行阻塞
// 其他线程就进行了阻塞，因此此时不会存在竞争去修改 head 的情况
private void setHead(Node node) {
    head = node;
    node.thread = null;
    node.prev = null;
}

// 看下 head 和 tail 的注释

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

// 上面的 head 和 tail 是 AbstractQueuedSynchronizer 的变量
// 他们都是 lazily initialized 的，也是说，在初始化的时候 head 和 tail 都是 null 需要进行初始化
// 而 AbstractQueuedSynchronizer#enq 方法包含了初始化的操作
// compareAndSetHead 方法先进行 head 的初始化
// head 初始化成功之后，新的 node 进行入队操作
private Node enq(final Node node) {
    for (;;) {
        Node t = tail;
        if (t == null) { // Must initialize 进行初始化
            if (compareAndSetHead(new Node()))// 初始化 head
                tail = head;// head  和 tail 是一样的，这里没有return 因此下次循环会再次执行 else 中的逻辑
        } else {
            node.prev = t;// 修改node.prev=tail 因为是入队操作，所以node 要在队的尾部
            if (compareAndSetTail(t, node)) {//入队成功,队列已经形成，修改 tail.next
                t.next = node;
                return t;
            }
        }
    }
}
```

## ReentrantLock.unlock 的实现

`ReentrantLock.unlock` 方法调用链

```java
ReentrantLock.unlock
  -> ReentrantLock.Sync.release
  -> tryRelease
  -> unparkSuccessor
```

## tryRelease

```java

// 执行 release
public void unlock() {
    sync.release(1);
}
// 执行 tryRelease
// 如果成功执行 unparkSuccessor
public final boolean release(int arg) {
    if (tryRelease(arg)) {
        Node h = head;
        if (h != null && h.waitStatus != 0)
            unparkSuccessor(h);// 把队列的 head 给 unparkSuccessor 方法
        return true;
    }
    return false;
}
// tryRelease 就是修改 state 的值(state-1)
protected final boolean tryRelease(int releases) {
    int c = getState() - releases;
    if (Thread.currentThread() != getExclusiveOwnerThread())
        throw new IllegalMonitorStateException();
    boolean free = false;
    if (c == 0) {
        free = true;
        setExclusiveOwnerThread(null);
    }
    setState(c);
    return free;
}
// 这里修改 state 没有使用 CAS 是因为：
// 当前线程肯定是获取锁成功的，其他线程肯定是阻塞状态
// 不存在其他线程同时修改 state 的情况，因此直接修改是可以的
protected final void setState(int newState) {
    state = newState;
}
```

## unparkSuccessor

```java
/**
 * Wakes up node's successor, if one exists.
 *
 * @param node the node
 */
// unparkSuccessor 方法从 head 找到下一个node
// 如果不为空存在就唤醒node 绑定的线程
// 为空，从tail找到一个合适的 node 进行线程唤醒
private void unparkSuccessor(Node node) {
    /*
     * If status is negative (i.e., possibly needing signal) try
     * to clear in anticipation of signalling.  It is OK if this
     * fails or if status is changed by waiting thread.
     */
    int ws = node.waitStatus;// 这里的 node 其实是 head
    if (ws < 0)// 可能存在 waitStatus 小于0的情况，如果是修改为0
        compareAndSetWaitStatus(node, ws, 0);
    /*
     * Thread to unpark is held in successor, which is normally
     * just the next node.  But if cancelled or apparently null,
     * traverse backwards from tail to find the actual
     * non-cancelled successor.
     */
    Node s = node.next;
    // 如果 head 的下一个 node 为空，从tail 找到一个进行锁的释放
    if (s == null || s.waitStatus > 0) {// 大于 0 waitStatus=CANCELLED 取消状态
        s = null;
        // 从 tail 队尾开始寻找
        for (Node t = tail; t != null && t != node; t = t.prev)
            if (t.waitStatus <= 0)
                s = t;
    }
    if (s != null)
        LockSupport.unpark(s.thread);
}
```

## waitStatus

`waitStatus` 的值&含义

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

## 公平锁&非公平锁的实现

`ReentrantLock` 使用两个内部类 `NonfairSync` 和 `FairSync` 来实现非公平锁和公平锁

![Sync.png](./images/Sync.png)

### NonfairSync

```java
static final class NonfairSync extends Sync {
    private static final long serialVersionUID = 7316153563782823691L;
    /**
     * Performs lock.  Try immediate barge, backing up to normal
     * acquire on failure.
     */
    final void lock() {
        // 非公平锁在获取锁的时候，直接尝试修改 AbstractQueuedSynchronizer 的 state 字段来获取锁
        // 如果修改成功，那么就获取锁成功
        if (compareAndSetState(0, 1))
            setExclusiveOwnerThread(Thread.currentThread());
        else
            acquire(1);// 尝试获取锁失败，就去获取锁
    }
    protected final boolean tryAcquire(int acquires) {
        return nonfairTryAcquire(acquires); // 执行 nonfairTryAcquire 方法获取锁
    }
}

// Sync#nonfairTryAcquire
// nonfairTryAcquire 与 FairSync 的 tryAcquire 少了一个 !hasQueuedPredecessors() 这个操作
// hasQueuedPredecessors 方法会检查是否有线程在队列中，如果没有才会尝试获取锁
final boolean nonfairTryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    if (c == 0) {
        if (compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {
        int nextc = c + acquires;
        if (nextc < 0) // overflow
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}
```

### FairSync

```java
static final class FairSync extends Sync {
    private static final long serialVersionUID = -3000897897090466540L;
    final void lock() {
        acquire(1);// 这里和 NonfairSync 的 lock  方法对比,少了一次尝试的动作
    }
    /**
     * Fair version of tryAcquire.  Don't grant access unless
     * recursive call or no waiters or is first.
     */
    protected final boolean tryAcquire(int acquires) {
        final Thread current = Thread.currentThread();
        int c = getState();
        if (c == 0) {
            if (!hasQueuedPredecessors() &&// 没有排队的线程才尝试获取锁，否则获取锁失败
                compareAndSetState(0, acquires)) {
                setExclusiveOwnerThread(current);
                return true;
            }
        }
        else if (current == getExclusiveOwnerThread()) {
            int nextc = c + acquires;
            if (nextc < 0)
                throw new Error("Maximum lock count exceeded");
            setState(nextc);
            return true;
        }
        return false;
    }
}

// 1. 有线程在排队
// 2. 排队的线程与当前线程不是同一个
public final boolean hasQueuedPredecessors() {
    // The correctness of this depends on head being initialized
    // before tail and on head.next being accurate if the current
    // thread is first in queue.
    Node t = tail; // Read fields in reverse initialization order
    Node h = head;
    Node s;
    return h != t &&
        ((s = h.next) == null || s.thread != Thread.currentThread());
}
```

## demo

```java
// 一个阻塞队列实现
class BlockArray<E> {

    Object[] element;


    int size;
    int count;
    int putprt;
    int takeptr;

    public BlockArray(int size) {
        this.size = size;
        element = new Object[size];
    }


    final ReentrantLock lock = new ReentrantLock();

    final Condition empty = lock.newCondition();

    final Condition full = lock.newCondition();


    public E put(E e) throws InterruptedException {
        lock.lock();
        try {
            while (count == size) {
                full.await();
            }
            element[putprt++] = e;
            if (putprt == size) {
                putprt = 0;
            }
            ++count;
            empty.signal();
        } finally {
            lock.unlock();
        }

        return e;
    }

    public E take() throws InterruptedException {
        E e = null;
        lock.lock();
        try {
            while (count == 0) {
                empty.await();
            }
            e = (E) element[takeptr++];
            if (takeptr == size) {
                takeptr = 0;
            }
            --count;
            full.signal();
        } finally {
            lock.unlock();
        }
        return e;
    }

}
    // test
    public static void main(String[] args) {
        BlockArray<Integer> blockArray = new BlockArray(5);

        new Thread(() -> {
            try {
                while (true) {
                    System.out.println("get " + blockArray.take());
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();

        IntStream.range(0, 10).forEach(i -> {
            try {
                blockArray.put(i);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });
    }

```

## Link

- [condition.md](condition.md)
- [count-down-latch.md](count-down-latch.md)
- [aqs.md](aqs.md)
- [https://tech.meituan.com/2018/11/15/java-lock.html](https://tech.meituan.com/2018/11/15/java-lock.html)
- [https://tech.meituan.com/2019/12/05/aqs-theory-and-apply.html](https://tech.meituan.com/2019/12/05/aqs-theory-and-apply.html)