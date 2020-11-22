# Condition

- [Condition](#condition)
  - [Condition interface](#condition-interface)
  - [ConditionObject](#conditionobject)
  - [AbstractQueuedSynchronizer.ConditionObject.await](#abstractqueuedsynchronizerconditionobjectawait)
  - [AbstractQueuedSynchronizer.fullyRelease](#abstractqueuedsynchronizerfullyrelease)
  - [AbstractQueuedSynchronizer.ConditionObject.signal](#abstractqueuedsynchronizerconditionobjectsignal)
  - [AbstractQueuedSynchronizer.ConditionObject.signalAll](#abstractqueuedsynchronizerconditionobjectsignalall)
  - [link](#link)

Condition factors out the Object monitor methods (wait, notify and notifyAll) into distinct objects to give the effect of having multiple wait-sets per object, by combining them with the use of arbitrary Lock implementations. Where a Lock replaces the use of synchronized methods and statements, a Condition replaces the use of the Object monitor methods.

`Condition` 类提供了类似 `Object` 类中的 `wait`, `notify` and `notifyAll` 方法，用来替换 `Object` 类，配合 `Lock` 类实现线程之间的通信(阻塞，唤醒)[`synchronized`](synchronized.md)

`Condition` 一定绑定了一个 `Lock` 实例。`Lock` 用来索取锁(`lock`)和释放(`unlock`)锁，而 `Condition` 主要是 为了阻塞(`await`)和唤醒(`signal`)线程的。

能调用 `await` 和 `signal` 方法的线程，一定是持有锁的线程。

## Condition interface

```java
public interface Condition {
    void await() throws InterruptedException;
    void awaitUninterruptibly();
    long awaitNanos(long nanosTimeout) throws InterruptedException;
    boolean await(long time, TimeUnit unit) throws InterruptedException;
    boolean awaitUntil(Date deadline) throws InterruptedException;
    void signal();
    void signalAll();
}
```

`ConditionObject` 是 `AbstractQueuedSynchronizer` 的内部类

下面从 `AbstractQueuedSynchronizer.ConditionObject` 来看下具体的实现

## ConditionObject

```java
// ConditionObject 实现了 Condition 接口
// 操作 queue 的方法有：
//  addConditionWaiter
//  unlinkCancelledWaiters
// ConditionObject 使用 firstWaiter 和 lastWaiter
// 来记录 queue 中第一个和最后一个元素(而queue 则是在 AbstractQueuedSynchronizer 中)
public class ConditionObject implements Condition, java.io.Serializable {
    private static final long serialVersionUID = 1173984872572414699L;
    /** First node of condition queue. */
    private transient Node firstWaiter;
    /** Last node of condition queue. */
    private transient Node lastWaiter;
    // 省略其它代码
}
```

## AbstractQueuedSynchronizer.ConditionObject.await

> 语义：

执行 `await` 方法会阻塞当前线程（当前线程必须持有锁）

当执行 signal 或者 signalAll 或者线程被 interrupted 中断之后线程再次被唤醒

Causes the current thread to wait until it is signalled or interrupted.
The lock associated with this `Condition` is atomically released and the current thread becomes disabled for thread scheduling purposes and lies dormant until one of four things happens:

4 种情况下，执行 `await` 的线程会被唤醒

- Some other thread invokes the `signal()` method for this `Condition` and the current thread happens to be chosen as the thread to be awakened; `or`
- Some other thread invokes the `signalAll()` method for this `Condition`; `or`
- Some other thread interrupts the current thread, and interruption of thread suspension is supported; `or`
- A "spurious wakeup" occurs.

> 看下 `await` 方法的源码实现

```java
// AbstractQueuedSynchronizer.ConditionObject
public final void await() throws InterruptedException {
    // 检测当前线程是否被 interrupted 了
    if (Thread.interrupted())
        throw new InterruptedException();
    // 加入到 queue 中
    // 其实就是把当前线程包装成 node 形成链表
    // 并且更新 lastWaiter 和 firstWaiter
    Node node = addConditionWaiter();
    // 尝试去释放锁
    int savedState = fullyRelease(node);
    int interruptMode = 0;
    // 如果不是在 queue 中 就进入阻塞
    // 如果不在queue中，即使被唤醒了，也再次进入阻塞
    // 这里需要与 signal 方法一起看(Node 其实是在执行signal的时候 执行 enq(node) 方法进入aqs 队列中的)
    // signal 会把 firstWaiter 放入 queue 中，同时返回 前一个node
    // 同时执行 unpark（唤醒） 前一个node关联的线程  唤醒阻塞的线程
    while (!isOnSyncQueue(node)) {
        // 如果不在 queue 中，那么就再次阻塞
        LockSupport.park(this);
        // 这里在被唤醒之后才会执行
        // 当 interruptMode 不等于 0 的时候，结束循环
        // checkInterruptWhileWaiting 会检测线程的状态 是否执行了中断操作
        if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)
            break;
    }
    // acquireQueued 会去尝试获取锁，这个方法返回true 标识线程被标记为中断状态
    // thread.interrupt 会把线程标记为中断的状态
    // acquireQueued 方法会阻塞线程，但是当线程唤醒的时候可能有二种情况：
    // 1. 执行了 unpark 方法，正常的唤醒
    // 2. 执行了 thread.interrupt 方法
    if (acquireQueued(node, savedState) && interruptMode != THROW_IE)
        // 更新次线程为中断状态
        interruptMode = REINTERRUPT;
    if (node.nextWaiter != null) // clean up if cancelled
        unlinkCancelledWaiters();
    if (interruptMode != 0)// 针对 THROW_IE 和 REINTERRUPT 进行处理
        // 如果是 THROW_IE 则抛出 InterruptedException 异常
        // 如果是 REINTERRUPT 执行 Thread.currentThread().interrupt();
        reportInterruptAfterWait(interruptMode);
}

// AbstractQueuedSynchronizer.ConditionObject
private Node addConditionWaiter() {
    Node t = lastWaiter;
    // If lastWaiter is cancelled, clean out.
    // 如果 queue 中最后一个 waiter(也就是线程) 取消了，那么就清除
    if (t != null && t.waitStatus != Node.CONDITION) {
        unlinkCancelledWaiters();
        t = lastWaiter;
    }
    Node node = new Node(Thread.currentThread(), Node.CONDITION);
    if (t == null)
        firstWaiter = node;// 第一次，就当做 firstWaiter
    else
        t.nextWaiter = node;// 进入 queue
    lastWaiter = node;// 更新 lastWaiter queue 中的最后一个元素
    return node;
}

// AbstractQueuedSynchronizer.ConditionObject
// 一个假想的 queue（queue 中有3个Node）
// firstWaiter <---- nextWaiter <---- lastWaiter <---- null
// 从方法名称就可以看到这个方法的作用，从 queue 中删除那些已经取消的 Node（也就是线程）
private void unlinkCancelledWaiters() {
    Node t = firstWaiter;
    Node trail = null;// 临时变量，记录不是取消状态的 Node
    while (t != null) {
        Node next = t.nextWaiter;// queue 中的下一个 Node
        if (t.waitStatus != Node.CONDITION) { // 不是 CONDITION 状态
            t.nextWaiter = null;// 与 queue 中的下一个取消引用关系，方便 GC 回收
            if (trail == null)// 这里只会执行一次，如果为空说明还没找到状态是 CONDITION 的 Node
                firstWaiter = next;// 更新 queue 头部
            else
                trail.nextWaiter = next;// 更新 nextWaiter 形成新的 queue
            if (next == null)// 如果下一个为空，说明是 queue 尾部了
                lastWaiter = trail;// 更新 queue 尾部
        }
        else
            trail = t;// 如果不是取消状态
        t = next;// 从下一个 Node 元素继续寻找
    }
}

```

## AbstractQueuedSynchronizer.fullyRelease

```java
// 如果释放锁失败，那就修改当前的线程的  waitStatus= CANCELLED
final int fullyRelease(Node node) {
    boolean failed = true;
    try {
        int savedState = getState();
        if (release(savedState)) {
            failed = false;
            return savedState;
        } else {
            throw new IllegalMonitorStateException();
        }
    } finally {
        if (failed)
            node.waitStatus = Node.CANCELLED;
    }
}
```

## AbstractQueuedSynchronizer.ConditionObject.signal

```java
public final void signal() {
    if (!isHeldExclusively())// 判断获取锁的线程是否是当前线程
        throw new IllegalMonitorStateException();
    Node first = firstWaiter;
    if (first != null)
        doSignal(first);
}
// 唤醒线程
// 从 ConditionObject 中的 firstWaiter(Node) 开始
// transferForSignal 会把 firstWaiter 放入到 AbstractQueuedSynchronizer 维护的 queue 中
private void doSignal(Node first) {
    do {
        if ( (firstWaiter = first.nextWaiter) == null)
            lastWaiter = null;
        first.nextWaiter = null;
    } while (!transferForSignal(first) &&
             (first = firstWaiter) != null);
}
// 在执行 signal 方法的时候
// 执行 enq 进入前到queue 中
final boolean transferForSignal(Node node) {
    /*
     * If cannot change waitStatus, the node has been cancelled.
     */
    if (!compareAndSetWaitStatus(node, Node.CONDITION, 0))
        return false;
    /*
     * Splice onto queue and try to set waitStatus of predecessor to
     * indicate that thread is (probably) waiting. If cancelled or
     * attempt to set waitStatus fails, wake up to resync (in which
     * case the waitStatus can be transiently and harmlessly wrong).
     */
    Node p = enq(node);
    // node 进入queue 之后，会返回它前面的Node
    int ws = p.waitStatus;
    // ws > 0 说明 线程已经取消了 就唤醒这个线程
    //
    if (ws > 0 || !compareAndSetWaitStatus(p, ws, Node.SIGNAL))
        LockSupport.unpark(node.thread);
    return true;
}
```

## AbstractQueuedSynchronizer.ConditionObject.signalAll

```java
public final void signalAll() {
    if (!isHeldExclusively())
        throw new IllegalMonitorStateException();
    Node first = firstWaiter;
    if (first != null)
        doSignalAll(first);
}
private void doSignalAll(Node first) {
    lastWaiter = firstWaiter = null;
    do {
        Node next = first.nextWaiter;
        first.nextWaiter = null;
        transferForSignal(first);
        first = next;
    } while (first != null);
}
```

## link

- [Condition](https://suichangkele.iteye.com/blog/2368254)
