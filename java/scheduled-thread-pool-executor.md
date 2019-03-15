# ScheduledThreadPoolExecutor

`ScheduledThreadPoolExecutor` = `ThreadPoolExecutor`+`ScheduledExecutorService`

![ScheduledThreadPoolExecutor](images/ScheduledThreadPoolExecutor.png)

- [ScheduledThreadPoolExecutor](#scheduledthreadpoolexecutor)
  - [java doc](#java-doc)
  - [scheduleAtFixedRate](#scheduleatfixedrate)
  - [scheduleWithFixedDelay](#schedulewithfixeddelay)
  - [ScheduledFutureTask](#scheduledfuturetask)
  - [变量](#%E5%8F%98%E9%87%8F)
    - [run](#run)
  - [getDelay](#getdelay)
  - [DelayedWorkQueue](#delayedworkqueue)
    - [offer](#offer)
    - [poll](#poll)
    - [take](#take)

1. `ScheduledThreadPoolExecutor` 支持周期性执行某一个任务
2. 包装 `Runnable` `Callable` 为 ScheduledFutureTask
3. 使用自定义的 `DelayedWorkQueue` 执行任务

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
                                      unit.toNanos(period));
    RunnableScheduledFuture<Void> t = decorateTask(command, sft);
    sft.outerTask = t;
    delayedExecute(t);
    return t;
}
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
                                      unit.toNanos(-delay));
    RunnableScheduledFuture<Void> t = decorateTask(command, sft);
    sft.outerTask = t;
    delayedExecute(t);
    return t;
}
```

## ScheduledFutureTask

![ScheduledFutureTask](images/ScheduledFutureTask.png)

## 变量

```java
/** Sequence number to break ties FIFO */
private final long sequenceNumber;
/** The time the task is enabled to execute in nanoTime units */
private long time;
/**
 * Period in nanoseconds for repeating tasks.  A positive
 * value indicates fixed-rate execution.  A negative value
 * indicates fixed-delay execution.  A value of 0 indicates a
 * non-repeating task.
 */
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

//
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

## getDelay

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

使用 `ReentrantLock` 控制并发

### offer

```java
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
            siftUp(i, e);
        }
        if (queue[0] == e) {
            leader = null;
            available.signal();
        }
    } finally {
        lock.unlock();
    }
    return true;
}
```

### poll

```java
        public RunnableScheduledFuture<?> poll(long timeout, TimeUnit unit)
            throws InterruptedException {
            long nanos = unit.toNanos(timeout);
            final ReentrantLock lock = this.lock;
            lock.lockInterruptibly();
            try {
                for (;;) {
                    RunnableScheduledFuture<?> first = queue[0];
                    if (first == null) {
                        if (nanos <= 0)
                            return null;
                        else
                            nanos = available.awaitNanos(nanos);
                    } else {
                        long delay = first.getDelay(NANOSECONDS);
                        if (delay <= 0)
                            return finishPoll(first);
                        if (nanos <= 0)
                            return null;
                        first = null; // don't retain ref while waiting
                        if (nanos < delay || leader != null)
                            nanos = available.awaitNanos(nanos);
                        else {
                            Thread thisThread = Thread.currentThread();
                            leader = thisThread;
                            try {
                                long timeLeft = available.awaitNanos(delay);
                                nanos -= delay - timeLeft;
                            } finally {
                                if (leader == thisThread)
                                    leader = null;
                            }
                        }
                    }
                }
            } finally {
                if (leader == null && queue[0] != null)
                    available.signal();
                lock.unlock();
            }
        }

```

### take

```java
public RunnableScheduledFuture<?> take() throws InterruptedException {
    final ReentrantLock lock = this.lock;
    lock.lockInterruptibly();
    try {
        for (;;) {
            RunnableScheduledFuture<?> first = queue[0];
            if (first == null)
                available.await();
            else {
                long delay = first.getDelay(NANOSECONDS);
                if (delay <= 0)
                    return finishPoll(first);
                first = null; // don't retain ref while waiting
                if (leader != null)
                    available.await();
                else {
                    Thread thisThread = Thread.currentThread();
                    leader = thisThread;
                    try {
                        available.awaitNanos(delay);
                    } finally {
                        if (leader == thisThread)
                            leader = null;
                    }
                }
            }
        }
    } finally {
        if (leader == null && queue[0] != null)
            available.signal();
        lock.unlock();
    }
}
```