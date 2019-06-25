# Condition

- [Condition (from oracle doc)](https://docs.oracle.com/javase/7/docs/api/java/util/concurrent/locks/Condition.html)

Condition factors out the Object monitor methods (wait, notify and notifyAll) into distinct objects to give the effect of having multiple wait-sets per object, by combining them with the use of arbitrary Lock implementations. Where a Lock replaces the use of synchronized methods and statements, a Condition replaces the use of the Object monitor methods.

`Condition` 类提供了类似 `Object` 类中的 `wait`, `notify` and `notifyAll` 方法，用来替换 `Object` 类，配合 `Lock` 类实现线程之间的通信[`synchronized`](synchronized.md)

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
// ConditionObject 使用 Node 来组成 queue
// 并使用 firstWaiter 和 lastWaiter 来维护queue 中第一个和最后一个元素
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

`await` 会释放 `Condition` 对应 `lock` 的锁，让其他程序获取锁

Causes the current thread to wait until it is signalled or interrupted.
The lock associated with this `Condition` is atomically released and the current thread becomes disabled for thread scheduling purposes and lies dormant until one of four things happens:

- Some other thread invokes the `signal()` method for this `Condition` and the current thread happens to be chosen as the thread to be awakened; `or`
- Some other thread invokes the `signalAll()` method for this `Condition`; `or`
- Some other thread interrupts the current thread, and interruption of thread suspension is supported; `or`
- A "spurious wakeup" occurs.

> 看下 `await` 方法的源码实现

```java
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
    while (!isOnSyncQueue(node)) {
        LockSupport.park(this);
        if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)
            break;
    }
    if (acquireQueued(node, savedState) && interruptMode != THROW_IE)
        interruptMode = REINTERRUPT;
    if (node.nextWaiter != null) // clean up if cancelled
        unlinkCancelledWaiters();
    if (interruptMode != 0)
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
    if (!isHeldExclusively())
        throw new IllegalMonitorStateException();
    Node first = firstWaiter;
    if (first != null)
        doSignal(first);
}
private void doSignal(Node first) {
    do {
        if ( (firstWaiter = first.nextWaiter) == null)
            lastWaiter = null;
        first.nextWaiter = null;
    } while (!transferForSignal(first) &&
             (first = firstWaiter) != null);
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
