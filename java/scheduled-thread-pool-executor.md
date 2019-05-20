# ScheduledThreadPoolExecutor

- [ScheduledThreadPoolExecutor](#scheduledthreadpoolexecutor)
  - [简介](#%E7%AE%80%E4%BB%8B)
  - [java doc](#java-doc)
  - [scheduleAtFixedRate](#scheduleatfixedrate)
  - [scheduleWithFixedDelay](#schedulewithfixeddelay)
  - [ScheduledFutureTask](#scheduledfuturetask)
    - [变量](#%E5%8F%98%E9%87%8F)
    - [run](#run)
    - [getDelay](#getdelay)
  - [DelayedWorkQueue](#delayedworkqueue)
    - [offer](#offer)
  - [siftUp](#siftup)
  - [ScheduledFutureTask-compareTo](#scheduledfuturetask-compareto)
    - [poll](#poll)
    - [take](#take)
  - [siftDown](#siftdown)

## 简介

1. `ScheduledThreadPoolExecutor` 支持周期性执行任务
2. 包装 `Runnable` `Callable` 为 `ScheduledFutureTask`
3. 使用自定义的 `DelayedWorkQueue` 维护任务,同时实现了优先级排序的功能
4. `ScheduledThreadPoolExecutor` = `ThreadPoolExecutor` + `ScheduledExecutorService`

![ScheduledThreadPoolExecutor](images/ScheduledThreadPoolExecutor.png)

## java doc

 This class specializes `ThreadPoolExecutor` implementation by

 1. Using a custom task type, `ScheduledFutureTask` for
    tasks, even those that don't require scheduling (i.e.,
    those submitted using `ExecutorService` execute, not
    `ScheduledExecutorService` methods) which are treated as
    delayed tasks with a delay of zero.

 2. Using a custom queue (`DelayedWorkQueue`), a variant of
    unbounded DelayQueue. The lack of capacity constraint and
    the fact that corePoolSize and `maximumPoolSize` are
    effectively identical simplifies some execution mechanics
    (see `delayedExecute`) compared to ThreadPoolExecutor.

 3. Supporting optional run-after-shutdown parameters, which
    leads to overrides of shutdown methods to remove and cancel
    tasks that should NOT be run after shutdown, as well as
    different recheck logic when task (re)submission overlaps
    with a shutdown.

 4. Task decoration methods to allow interception and
    instrumentation, which are needed because subclasses cannot
    otherwise override submit methods to get this effect. These
    don't have any impact on pool control logic though.

## scheduleAtFixedRate

```java
public ScheduledFuture<?> scheduleAtFixedRate(Runnable command,
                                              long initialDelay,
                                              long period,
                                              TimeUnit unit) {
    if (command == null || unit == null)
        throw new NullPointerException();
    if (period <= 0)
        throw new IllegalArgumentException();
    ScheduledFutureTask<Void> sft =
        new ScheduledFutureTask<Void>(command,
                                      null,
                                      triggerTime(initialDelay, unit),
                                      unit.toNanos(period));// 不同点
    RunnableScheduledFuture<Void> t = decorateTask(command, sft);
    sft.outerTask = t;
    delayedExecute(t);
    return t;
}
```

`scheduleAtFixedRate` 与 `scheduleWithFixedDelay` 不同点在这个方法

```java
unit.toNanos(period));// scheduleAtFixedRate
unit.toNanos(-delay));// scheduleWithFixedDelay

// 这个值会被当做 ScheduledFutureTask 的成员变量 period
// 用来区分 scheduleAtFixedRate scheduleWithFixedDelay
// 用 setNextRunTime 计算下次执行的时间
```

## scheduleWithFixedDelay

```java
public ScheduledFuture<?> scheduleWithFixedDelay(Runnable command,
                                                 long initialDelay,
                                                 long delay,
                                                 TimeUnit unit) {
    if (command == null || unit == null)
        throw new NullPointerException();
    if (delay <= 0)
        throw new IllegalArgumentException();
    ScheduledFutureTask<Void> sft =
        new ScheduledFutureTask<Void>(command,
                                      null,
                                      triggerTime(initialDelay, unit),
                                      unit.toNanos(-delay));// 不同点
    RunnableScheduledFuture<Void> t = decorateTask(command, sft);
    sft.outerTask = t;
    delayedExecute(t);
    return t;
}
```

## ScheduledFutureTask

![ScheduledFutureTask](images/ScheduledFutureTask.png)

### 变量

```java
/** Sequence number to break ties FIFO */
private final long sequenceNumber;
/** The time the task is enabled to execute in nanoTime units */
private long time;// 任务执行的时间
/**
 * Period in nanoseconds for repeating tasks.  A positive
 * value indicates fixed-rate execution.  A negative value
 * indicates fixed-delay execution.  A value of 0 indicates a
 * non-repeating task.
 */
 // period > 0 fixed-rate
 // period < 0 fixed-delay
private final long period;
/** The actual task to be re-enqueued by reExecutePeriodic */
RunnableScheduledFuture<V> outerTask = this;
/**
 * Index into delay queue, to support faster cancellation.
 */
int heapIndex;
```

### run

```java
public void run() {
    boolean periodic = isPeriodic();
    if (!canRunInCurrentRunState(periodic))
        cancel(false);
    else if (!periodic)
        ScheduledFutureTask.super.run();// 不是周期性的任务，直接执行这个任务
    else if (ScheduledFutureTask.super.runAndReset()) {
        // 更新下次要执行时间
        setNextRunTime();
        // 把任务从新添加到 queue 队列中，从而可以周期性的执行这个任务
        reExecutePeriodic(outerTask);
    }
}

public boolean isPeriodic() {
    return period != 0;
}

// 如果 period > 0 认为是 scheduleAtFixedRate 类型的任务 tiem = tiem + period
// 而 period < 0 认为是 scheduleWithFixedDelay 类型的任务 tiem = now() + period
// 在这些方法执行已经执行了 isPeriodic 方法 因此 period !=0
private void setNextRunTime() {
    long p = period;
    if (p > 0)// scheduleAtFixedRate
        time += p;
    else
        time = triggerTime(-p);// scheduleWithFixedDelay
}

long triggerTime(long delay) {
    return now() +
        ((delay < (Long.MAX_VALUE >> 1)) ? delay : overflowFree(delay));
}

// 任务执行之后，被重新放进了队列中
void reExecutePeriodic(RunnableScheduledFuture<?> task) {
    if (canRunInCurrentRunState(true)) {
        super.getQueue().add(task);
        if (!canRunInCurrentRunState(true) && remove(task))
            task.cancel(false);
        else
            ensurePrestart();
    }
}
```

### getDelay

```java
// getDelay 获取还需要等待的时间
// getDelay 方法 在 DelayedWorkQueue#take 和 DelayedWorkQueue#poll 中调用
// 如果返回的值大于0，就会执行 available.awaitNanos(nanos); 阻塞 nanos 纳秒
public long getDelay(TimeUnit unit) {
    return unit.convert(time - now(), NANOSECONDS);
}
```

## DelayedWorkQueue

![DelayedWorkQueue](images/DelayedWorkQueue.png)

`DelayedWorkQueue` 是基于数组实现的一个队列,初始大小是 16

使用 `ReentrantLock` 控制并发,重写了 `offer`,`take`,`poll` 方法

### offer

```java
// offer 向 DelayedWorkQueue 维护的数组中添加一个任务
// 如果空间不足就扩容
public boolean offer(Runnable x) {
    if (x == null)
        throw new NullPointerException();
    RunnableScheduledFuture<?> e = (RunnableScheduledFuture<?>)x;
    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
        int i = size;
        if (i >= queue.length)
            grow();// 扩容
        size = i + 1;
        if (i == 0) {
            queue[0] = e;
            setIndex(e, 0);
        } else {
            siftUp(i, e);// 见下面的解释
        }
        if (queue[0] == e) {// 如果是第一次插入数据
            leader = null;
            // 这里去唤醒调用 take 方法
            // take 方法可能在 offer 方法之前执行
            // 此时 queue 为空 ,take 方法会执行 available.await(); 进行阻塞等待
            // 这里的目的就是唤醒阻塞的线程(这个线程其实就是线程池中的 worker 线程)
            available.signal();
        }
    } finally {
        lock.unlock();
    }
    return true;
}
```

## siftUp

```java
/**
 * Sifts element added at bottom up to its heap-ordered spot.
 * Call only when holding lock.
 */
// siftUp -> 向上筛选
// k 是当前元素插入的位置,key 是当前插入的元素
// 每次向 queue 中插入元素的时候，都会与 queue 的元素进行比较
// 把比较小的元素移动到queue的头部(进行位置的交换)
// 这里并不会对每个元素都进行比较，而是除 2 进行跳跃的数据对比（交换位置）
private void siftUp(int k, RunnableScheduledFuture<?> key) {
    while (k > 0) {
        // 这个公式可以转化成 parent = (k - 1) / 2;
        // 使用 >>> 代替 / 是因为位操纵较快
        int parent = (k - 1) >>> 1;
        RunnableScheduledFuture<?> e = queue[parent];
        if (key.compareTo(e) >= 0)// 如果插入的数据比之前的数据大，就应该排在 queue 的末尾，结束循环
            break;
        queue[k] = e;
        setIndex(e, k);
        k = parent;
    }
    queue[k] = key;// 把新的key 移动到合适的位置(其实由于k较小，所以放在queue 的头部)
    setIndex(key, k);
}
```

## ScheduledFutureTask-compareTo

```java
// ScheduledFutureTask
// 每个被提交到线程池中的任务，都会被包装成 ScheduledFutureTask
// 这里重写了compareTo
public int compareTo(Delayed other) {
    if (other == this) // compare zero if same object
        return 0;
    if (other instanceof ScheduledFutureTask) {
        ScheduledFutureTask<?> x = (ScheduledFutureTask<?>)other;
        // time 是task 的执行时间，是通过 triggerTime 计算出来的
        long diff = time - x.time;
        if (diff < 0)// 时间较小的，向queue的头部靠近
            return -1;
        else if (diff > 0)
            return 1;
        else if (sequenceNumber < x.sequenceNumber)
            // 如果时间相等，对比 进入queue的顺序，先进入queue的，向queue的头部靠近
            return -1;
        else
            return 1;
    }
    // 延迟时间小的，排在前面
    long diff = getDelay(NANOSECONDS) - other.getDelay(NANOSECONDS);
    return (diff < 0) ? -1 : (diff > 0) ? 1 : 0;
}
```

### poll

可参考 `take` 方法的实现

### take

```java
public RunnableScheduledFuture<?> take() throws InterruptedException {
    final ReentrantLock lock = this.lock;
    lock.lockInterruptibly();
    try {
        for (;;) {
            RunnableScheduledFuture<?> first = queue[0];
            // 如果没有数据则等待,如果其他线程执行了 offer 提交了任务
            // 会执行 available.signal(); 唤醒 take （也就是线程池的线程）
            if (first == null)
                available.await();
            else {
                // 计算延迟的时间 delay = time - now()
                long delay = first.getDelay(NANOSECONDS);
                if (delay <= 0)// 小于 0 说明时间到了,返回这个 Runnable
                    return finishPoll(first);// 这里保证了 queue 一定是有一个任务的
                first = null; // don't retain ref while waiting
                // worker 线程可能有多个，如果检测到其他线程竞争，则阻塞
                // 会在 finally 中进行唤醒
                // 或许你认为上面不是使用 lock 进行加锁了为什么还有其他线程竞争呢？
                // 这是因为后面会执行 available.awaitNanos(delay) 是会释放锁的，因此其他线程也可获取锁
                if (leader != null)
                    available.await();
                else {
                    Thread thisThread = Thread.currentThread();
                    leader = thisThread;
                    try {
                        // 等待 delay 纳秒时间，其实就是在 delay 纳秒之后返回 Runnable
                        // 然后提交给 queue 执行任务
                        // 这样就实现了 周期性任务 的执行
                        // awaitNanos 方法会使当前线程阻塞，等待唤醒（不会占用CPU）
                        available.awaitNanos(delay);
                    } finally {
                        if (leader == thisThread)
                            leader = null;// 这里设置为 null,后续在 finally 中唤醒其他线程
                    }
                }
            }
        }
    } finally {
        if (leader == null && queue[0] != null)
            available.signal();// 这里唤醒阻塞的线程
        lock.unlock();
    }
}

// time 是任务要执行的时间点
// time - now() < 0 说明已经超过了当前时间
// 立即执行
public long getDelay(TimeUnit unit) {
    return unit.convert(time - now(), NANOSECONDS);
}

/**
* Performs common bookkeeping for poll and take: Replaces
* first element with last and sifts it down.  Call only when
* holding lock.
* @param f the task to remove and return
*/
// 这里是从数据中拿到下一个需要执行的任务
private RunnableScheduledFuture<?> finishPoll(RunnableScheduledFuture<?> f) {
    int s = --size;// 下一个
    RunnableScheduledFuture<?> x = queue[s];
    queue[s] = null;
    if (s != 0)
        siftDown(0, x);
    setIndex(f, -1);// 更新 heapIndex 方便后续排序使用
    return f;
}
```

## siftDown

```java
/**
 * Sifts element added at top down to its heap-ordered spot.
 * Call only when holding lock.
 */
private void siftDown(int k, RunnableScheduledFuture<?> key) {
    int half = size >>> 1;
    while (k < half) {
        int child = (k << 1) + 1;
        RunnableScheduledFuture<?> c = queue[child];
        int right = child + 1;
        if (right < size && c.compareTo(queue[right]) > 0)
            c = queue[child = right];
        if (key.compareTo(c) <= 0)
            break;
        queue[k] = c;
        setIndex(c, k);
        k = child;
    }
    queue[k] = key;
    setIndex(key, k);
}
```