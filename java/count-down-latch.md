# CountDownLatch

- [CountDownLatch](#countdownlatch)
  - [concept](#concept)
  - [init](#init)
  - [await](#await)
  - [countDown](#countdown)
  - [example1](#example1)
  - [example2](#example2)
  - [example3](#example3)
  - [参考](#%E5%8F%82%E8%80%83)

`CountDownLatch` 可用来实现线程之间的协作(或者理解为一个`计数器`)，如线程 A 等待线程 B,C,D 执行完成之后，再进行继续其他操作

类似 `Thread#join` 的方法, `Thread#join` 可参照这个 [thread-join](thread.md#join)

这里通过 `await` 和 `countDown` 方法的实现来分析的 `CountDownLatch` 的原理

在开始之前，需要理解下面 `aqs` 相关的知识，阅读起来才不费力

预先了解的知识：

- [java.util.concurrent.locks.AbstractQueuedSynchronizer](aqs.md)
- [java.util.concurrent.locks.LockSupport](lock-support.md)

## concept

在下面的例子中，会把 `CountDownLatch` 当做 `计数器` 来解说

`CountDownLatch` 可以用来处理几个线程之间的协作，如 A 线程等待 B,C,D 线程任务完成之后，再执行 A 自己的任务。

A synchronization aid that allows one or more threads to wait until
a set of operations being performed in other threads completes.

## init

```java
public class CountDownLatchTest {
    public static void main(String[] args) throws InterruptedException {

        // 这里进行初始化，参数是2,需要执行两次 countDown （计数器减少2，执行两次）
        // await 才会继续执行
        CountDownLatch cdl = new CountDownLatch(2);
        Runnable r = () -> {
            try {
                TimeUnit.SECONDS.sleep(1);
                System.out.println("sleep end");
                //cdl.countDown();
                //cdl.countDown();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        };
        // 这里使用一个新的线程进行 countDown 操作
        // 主线程执行了 await，因此一直在阻塞
        new Thread(r).start();
        cdl.await();// 线程进行等待

        System.out.println("end");

    }
}
```

`new CountDownLatch()`

```java
// 在进行 new CountDownLatch 会创建一个 Sync 对象
// Sync 是 CountDownLatch 的内部类
// Sync 继承了 AbstractQueuedSynchronizer 实现了锁的功能
public CountDownLatch(int count) {
    if (count < 0) throw new IllegalArgumentException("count < 0");
    this.sync = new Sync(count);
}
```

## await

分析 `await` 为什么为使线程阻塞

上面的 `await` 方法会使当前线程阻塞，而当前获取的方式一般是通过 `Thread.currentThread()` 方便的获取

```java
// CountDownLatch
public void await() throws InterruptedException {
        sync.acquireSharedInterruptibly(1);
}
```

```java
// AbstractQueuedSynchronizer
public final void acquireSharedInterruptibly(int arg)
        throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    // 首先通过 tryAcquireShared 尝试一下获取锁
    // 其实就是判断一下 state 是否等于0
    // 如果小于 0 说明,计数器不为0,需要等待,否则不需要阻塞
    if (tryAcquireShared(arg) < 0)
        doAcquireSharedInterruptibly(arg);
}
// CountDownLatch
protected int tryAcquireShared(int acquires) {
    // -1 表示还有其他线程在获取锁
    return (getState() == 0) ? 1 : -1;
 }
```

```java
// AbstractQueuedSynchronizer
// 下面的 for;; + shouldParkAfterFailedAcquire 方法实现了cas 语义
private void doAcquireSharedInterruptibly(int arg)
    throws InterruptedException {
    // 当前线程进入队列排队
    final Node node = addWaiter(Node.SHARED);
    boolean failed = true;
    try {
        for (;;) {
            final Node p = node.predecessor();// 获取当前的节点的前一个节点
            if (p == head) {// 如果前一个节点为 head 说明只有一个线程在排队，进行尝试获取 计数器
                int r = tryAcquireShared(arg);
                if (r >= 0) {// 计数器为 0 了，不需要阻塞了
                    setHeadAndPropagate(node, r);// 对于 CountDownLatch 这个代码不会执行
                    p.next = null; // help GC
                    failed = false;
                    return;
                }
            }
            // shouldParkAfterFailedAcquire + for 循环，去改变前一个节点的状态
            // 直到修改成功（也是cas）
            // shouldParkAfterFailedAcquire 会修改前一个 Node 节点的 waitStatus = Node.SIGNAL
            // 修改成功，才会阻塞当前线程(执行parkAndCheckInterrupt)
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())// parkAndCheckInterrupt 这里使用 LockSupport.park 阻塞当前线程
                throw new InterruptedException();
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}
// AbstractQueuedSynchronizer
private Node addWaiter(Node mode) {
    // 把当前线程包装成 Node
    Node node = new Node(Thread.currentThread(), mode);
    // Try the fast path of enq; backup to full enq on failure
    Node pred = tail;// 队尾
    if (pred != null) {
        node.prev = pred;
        // 队尾 不为空，说明有线程在排队，那么当前线程，也就是node 变成 tail
        if (compareAndSetTail(pred, node)) {// 这里尝试变成tail,如果成功，就返回当前 Node
            pred.next = node;
            return node;
        }
    }
    enq(node);// 入队失败或者队尾不为空，那么执行入队操作
    return node;
}
// AbstractQueuedSynchronizer
private Node enq(final Node node) {
    // 这里一个无线循环
    // 也就是 cas 一直循环到设置成功
    // 这里是有 cas 的目的是多线程的时候，会存在竞争，存在 head 或者tail 已经被其他线程初始化的情况
    // cas 成功，结束循环
    for (;;) {
        Node t = tail;// 第一次 tail 为空的时候，进行初始化 head 和 tail
        if (t == null) { // Must initialize
            if (compareAndSetHead(new Node()))
                tail = head;
        } else {
            node.prev = t;
            if (compareAndSetTail(t, node)) {
                t.next = node;
                return t;
            }
        }
    }
}
```

## countDown

分析 `countDown` 为什么会使线程取消阻塞状态

```java
// CountDownLatch
public void countDown() {
        sync.releaseShared(1);// 计数器 -1
}

// AbstractQueuedSynchronizer
public final boolean releaseShared(int arg) {
        if (tryReleaseShared(arg)) {// 尝试释放锁
            doReleaseShared();// 返回 false 就不执行这个，存在其他线程已经执行了 countDown
            return true;
        }
        return false;
}
// CountDownLatch
protected boolean tryReleaseShared(int releases) {
            // Decrement count; signal when transition to zero
            for (;;) {
                int c = getState();
                if (c == 0)// 如果 state =0 说明其他线程已经执行 countDown 了，返回 false
                    return false;
                int nextc = c-1;// 这里使用 for + cas 把 state-1
                if (compareAndSetState(c, nextc))
                    return nextc == 0;
            }
}

// AbstractQueuedSynchronizer
// 这里会有唤醒线程的操作 unparkSuccessor
private void doReleaseShared() {
        /*
         * Ensure that a release propagates, even if there are other
         * in-progress acquires/releases.  This proceeds in the usual
         * way of trying to unparkSuccessor of head if it needs
         * signal. But if it does not, status is set to PROPAGATE to
         * ensure that upon release, propagation continues.
         * Additionally, we must loop in case a new node is added
         * while we are doing this. Also, unlike other uses of
         * unparkSuccessor, we need to know if CAS to reset status
         * fails, if so rechecking.
         */
        for (;;) {
            Node h = head;
            if (h != null && h != tail) {// head 不等于 tail 说明至少有一个线程在队列中
                int ws = h.waitStatus;// 获取 head 的状态
                if (ws == Node.SIGNAL) {// 如果是需要唤醒的状态，修改 waitStatus
                    if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))// 　修改失败，继续修改
                        continue;            // loop to recheck cases
                    unparkSuccessor(h);// 修改 waitStatus 成功，唤醒线程
                }
                // 　如果 waitStatus =0 说明线程进入队列还没有成功，继续循环，等进入对列成功执行
                // 这里的修改 waitStatus=PROPAGATE 其实对 CountDownLatch 的实现没什么作用
                else if (ws == 0 &&
                         !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
                    continue;                // loop on failed CAS
            }
            // h == head 这里　就是 if(true) 的写法
            // 只有当上面的判断 h != null && h != tail 不成立了，才会执行下面的代码
            // 比如 head 为空了，或者 head == tail 了
            // head==tail 说明有线程出队列了，因此结束循环
            if (h == head)                   // loop if head changed
                break;
        }
}
// AbstractQueuedSynchronizer
private void unparkSuccessor(Node node) {
        /*
         * If status is negative (i.e., possibly needing signal) try
         * to clear in anticipation of signalling.  It is OK if this
         * fails or if status is changed by waiting thread.
         */
        // doReleaseShared 中其实已经把 waitStatus 改成 0了
        // 如果被其他线程该了，尝试修改成 0
        int ws = node.waitStatus;
        if (ws < 0)
            compareAndSetWaitStatus(node, ws, 0);

        /*
         * Thread to unpark is held in successor, which is normally
         * just the next node.  But if cancelled or apparently null,
         * traverse backwards from tail to find the actual
         * non-cancelled successor.
         */
         // 对于 CountDownLatch 来说 s!=null waitStatus 也不会取消
        Node s = node.next;
        if (s == null || s.waitStatus > 0) {// waitStatus 大于 0 是取消状态
            s = null;
            for (Node t = tail; t != null && t != node; t = t.prev)
                if (t.waitStatus <= 0)// 线程的状态需要唤醒，
                    s = t;
        }
        if (s != null)
            LockSupport.unpark(s.thread);// 唤醒线程
}
```

## example1

The first is a start signal that prevents any worker from proceeding
until the driver is ready for them to proceed;
The second is a completion signal that allows the driver to wait
until all workers have completed.

```java
class Driver {
  void main() throws InterruptedException {
    // startSignal 开始的信号
    CountDownLatch startSignal = new CountDownLatch(1);
    //  完成的信号
    CountDownLatch doneSignal = new CountDownLatch(N);
     for (int i = 0; i < N; ++i) // create and start threads
      new Thread(new Worker(startSignal, doneSignal)).start();
     doSomethingElse();            // don't let run yet
    // 发出开始的信号
    startSignal.countDown();      // let all threads proceed
    doSomethingElse();
    // 完成的信号进行等待（等待所有线程完成任务）
    doneSignal.await();           // wait for all to finish
  }
}
 class Worker implements Runnable {
  private final CountDownLatch startSignal;
  private final CountDownLatch doneSignal;
  Worker(CountDownLatch startSignal, CountDownLatch doneSignal) {
    this.startSignal = startSignal;
    this.doneSignal = doneSignal;
  }
  public void run() {
    try {
      // 这里是异步的，每个线程都等待 开始的信号
      startSignal.await();
      doWork();
      // 每个线程执行之后，通知说：我完成了任务
      doneSignal.countDown();
    } catch (InterruptedException ex) {} // return;
  }
   void doWork() {
       // ...
    }
}
```

## example2

Another typical usage would be to divide a problem into N parts,
describe each part with a Runnable that executes that portion and
counts down on the latch, and queue all the `Runnables` to an
Executor. When all sub-parts are complete, the coordinating thread
will be able to pass through await. (When threads must repeatedly
count down in this way, instead use a {@link `CyclicBarrier`}.)

```java
class Driver2 {
   void main() throws InterruptedException {
     CountDownLatch doneSignal = new CountDownLatch(N);
     Executor e = //...
     for (int i = 0; i < N; ++i) // create and start threads
       e.execute(new WorkerRunnable(doneSignal, i));
     // 在其它线程完成任务之前，主线程一直阻塞
     doneSignal.await();           // wait for all to finish
   }
 }
 class WorkerRunnable implements Runnable {
   private final CountDownLatch doneSignal;
   private final int i;
   WorkerRunnable(CountDownLatch doneSignal, int i) {
     this.doneSignal = doneSignal;
     this.i = i;
   }
   public void run() {
     try {
       doWork(i);
       doneSignal.countDown();
     } catch (InterruptedException ex) {} // return;
   }
   void doWork() { /* ...*/ }
 }
```

[Thread#join()](thread.md#join)A 程等待 B 线程执行完毕之后，A 线程继续执行，实现了二个线程协作的机制

`CountDownLatch`A 线程等待 B,C,D,E 线程等完成之后，A 线程继续执行，实现了 N 个线程之间的协作机制

## example3

```java
    /**
     *  模拟一个开会的场景，10人到齐了，会议开始
     *
     * @param args
     * @throws InterruptedException
     */
    public static void main(String[] args) throws InterruptedException {

        // 10人
        int meeters = 10;
        CountDownLatch enter = new CountDownLatch(1);
        CountDownLatch arrive = new CountDownLatch(meeters);


        for (int i = 0; i < meeters; i++) {
            new Thread(() -> {
                try {
                    enter.await();
                    doWork();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    arrive.countDown();

                }

            }).start();
        }

        // 开始入场
        enter.countDown();
        // 等待人到齐
        arrive.await();
        // 人到齐了，开始开会
        System.out.println("meet begin...");
    }

    private static void doWork() {
        String name = Thread.currentThread().getName();
        System.out.println(name + " arrive ...");
    }
```

## 参考

- [CountDownLatch & CyclicBarrier](https://github.com/CL0610/Java-concurrency/tree/master/25.%E5%A4%A7%E7%99%BD%E8%AF%9D%E8%AF%B4java%E5%B9%B6%E5%8F%91%E5%B7%A5%E5%85%B7%E7%B1%BB-CountDownLatch%EF%BC%8CCyclicBarrier)
- [CountDownLatch](https://www.cnblogs.com/shiyanch/archive/2011/04/04/2005233.html)
- [CountDownLatch from oracle docs](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CountDownLatch.html)