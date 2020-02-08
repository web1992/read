# dubbo HashedWheelTimer

- [dubbo HashedWheelTimer](#dubbo-hashedwheeltimer)
  - [引言](#%e5%bc%95%e8%a8%80)
  - [interface](#interface)
  - [Timer](#timer)
  - [HashedWheelTimer](#hashedwheeltimer)
  - [TimerTask](#timertask)
  - [Timeout](#timeout)
  - [HashedWheelTimeout](#hashedwheeltimeout)
  - [HashedWheelBucket](#hashedwheelbucket)
  - [HashedWheelTimer 的创建](#hashedwheeltimer-%e7%9a%84%e5%88%9b%e5%bb%ba)
  - [newTimeout 定时任务的插入](#newtimeout-%e5%ae%9a%e6%97%b6%e4%bb%bb%e5%8a%a1%e7%9a%84%e6%8f%92%e5%85%a5)
  - [Worker](#worker)

`dubbo` 定时任务的实现，来自于 `Netty` 的源码

## 引言

这里简单说下为什么要使用 `HashedWheelTimer` 创建和管理`定时任务`

假如我们自己来实现一个定时器，用来创建和管理定时任务，通常会使用`数组`和`链表`来进行定时任务的创建，插入和删除

同时使用一个线程来检查`数组`或者`链表`里面定时任务是否到了需要执行的时间，到了就执行任务，并把定时任务删除。

但是当`定时任务`越来越多的时候，`数组`和`链表`的性能问题(遍历和删除性能)就会暴露出来。因此需要一种`算法`来替代他们

而 `HashedWheelTimer` 就是基于`时间轮算法`的替代者

## interface

和定时任务有关系的类：

- `Timer` 定时器的抽象类，默认实现是 `HashedWheelTimer`
- `HashedWheelTimer` 定时器，用来执行定时任务
- `TimerTask` 定时任务
- `Timeout` 定时任务状态查询的抽象类
- `HashedWheelTimeout` 提交给定时器之后，默认返回的 `TimeOut` 实现
- `HashedWheelBucket` 用来存放定时任务的容器
- `Worker` 定时器对应的线程

核心实现类是 `HashedWheelTimer` `HashedWheelBucket` `Worker`

## Timer

定时器的抽象接口

```java
public interface Timer {
    // 添加等待任务
    Timeout newTimeout(TimerTask task, long delay, TimeUnit unit);
    // 关闭定时器
    Set<Timeout> stop();
    // 查询定时器是否已经关闭
    boolean isStop();
}
```

## HashedWheelTimer

基于 `hash轮` 实现的定时器

## TimerTask

定时器执行的任务，用户自定义的定时任务，都需要实现这个接口

```java
public interface TimerTask {
    void run(Timeout timeout) throws Exception;
}
```

## Timeout

定时任务提交给 `Timer` 之后返回的结果，可通过 `Timeout` 查询任务的状态，取消任务，查询定时器和任务

`Timeout` 的定义如下：

```java
public interface Timeout {

    Timer timer();

    TimerTask task();

    boolean isExpired();

    boolean isCancelled();

    boolean cancel();
}
```

## HashedWheelTimeout

定时任务提交给定时器之后，默认的返回 `TimeOut` 的实现类

## HashedWheelBucket

`HashedWheelBucket` 用链表的数据结构来存储 `HashedWheelTimeout`

而 `HashedWheelTimeout` 中包含了 `TimerTask`

## HashedWheelTimer 的创建

可以在 `Dubbo` 中 `DefaultFuture` 找到 `HashedWheelTimer` 的创建

```java
// DefaultFuture
public static final Timer TIME_OUT_TIMER = new HashedWheelTimer(
        new NamedThreadFactory("dubbo-future-timeout", true),
        30,
        TimeUnit.MILLISECONDS);
```

`HashedWheelTimer` 的构造方法

```java
// HashedWheelTimer
// tickDuration -> 定时任务的 tick 时间
// 比如，我们生活中使用的机械时钟每一秒走一次
// tickDuration=100 ms 表示每 100 秒走一次
// ticksPerWheel -> 时间轮的大小，也就是数组的大小
// maxPendingTimeouts -> 当任务插入不进去的时候，允许最大的阻塞的定时任务
public HashedWheelTimer(
        ThreadFactory threadFactory,
        long tickDuration, TimeUnit unit, int ticksPerWheel,
        long maxPendingTimeouts) {
    // ...
    // 省略一些参数校验
    // Normalize ticksPerWheel to power of two and initialize the wheel.
    // 创建时间轮
    wheel = createWheel(ticksPerWheel);// 这个是初始化的核心方法
    // 初始化 mask
    mask = wheel.length - 1;
    // Convert tickDuration to nanos.
    this.tickDuration = unit.toNanos(tickDuration);
    // Prevent overflow.
    if (this.tickDuration >= Long.MAX_VALUE / wheel.length) {
        throw new IllegalArgumentException(String.format(
                "tickDuration: %d (expected: 0 < tickDuration in nanos < %d",
                tickDuration, Long.MAX_VALUE / wheel.length));
    }
    // 创建线程
    workerThread = threadFactory.newThread(worker);
    this.maxPendingTimeouts = maxPendingTimeouts;
    // 检查是否创建了太多的 HashedWheelTimer 实例
    // HashedWheelTimer 设计的目的就是为了用一个线程管理大量的 定时任务
    // 如果你创建了太多的 HashedWheelTimer 就提示错误(创建HashedWheelTimer的同时也会创建一个线程)
    if (INSTANCE_COUNTER.incrementAndGet() > INSTANCE_COUNT_LIMIT &&
            WARNED_TOO_MANY_INSTANCES.compareAndSet(false, true)) {
        reportTooManyInstances();
    }
}
// 初始化时间轮数组，用来存放定时任务
private static HashedWheelBucket[] createWheel(int ticksPerWheel) {
    // ...
    // 省略参数校验
    ticksPerWheel = normalizeTicksPerWheel(ticksPerWheel);
    HashedWheelBucket[] wheel = new HashedWheelBucket[ticksPerWheel];
    for (int i = 0; i < wheel.length; i++) {
        wheel[i] = new HashedWheelBucket();
    }
    return wheel;
}
// 把一个数字变成 2 的N 次方（2整数倍）
// 这里简单说下为什么时间轮的长读要是 2 的N次方
// ticksPerWheel 默认是 512
// 通常我们使用(取模运算)25%512 =25 来计算一个值应该放在数组的那个位置上
// 而我们可以使用 25&511 25 位运算来代替 % 运算，&位运算 比 %运算 速度快
// 因此这里会把ticksPerWheel变成2的倍数
// 而 mask = wheel.length - 1;
private static int normalizeTicksPerWheel(int ticksPerWheel) {
    int normalizedTicksPerWheel = ticksPerWheel - 1;
    normalizedTicksPerWheel |= normalizedTicksPerWheel >>> 1;
    normalizedTicksPerWheel |= normalizedTicksPerWheel >>> 2;
    normalizedTicksPerWheel |= normalizedTicksPerWheel >>> 4;
    normalizedTicksPerWheel |= normalizedTicksPerWheel >>> 8;
    normalizedTicksPerWheel |= normalizedTicksPerWheel >>> 16;
    return normalizedTicksPerWheel + 1;
}
```

## newTimeout 定时任务的插入

```java
// HashedWheelTimer
public Timeout newTimeout(TimerTask task, long delay, TimeUnit unit) {
    if (task == null) {
        throw new NullPointerException("task");
    }
    if (unit == null) {
        throw new NullPointerException("unit");
    }
    long pendingTimeoutsCount = pendingTimeouts.incrementAndGet();
    if (maxPendingTimeouts > 0 && pendingTimeoutsCount > maxPendingTimeouts) {
        pendingTimeouts.decrementAndGet();
        throw new RejectedExecutionException("Number of pending timeouts ("
                + pendingTimeoutsCount + ") is greater than or equal to maximum allowed pending "
                + "timeouts (" + maxPendingTimeouts + ")");
    }
    // 启动定时器线程
    start();
    // Add the timeout to the timeout queue which will be processed on the next tick.
    // During processing all the queued HashedWheelTimeouts will be added to the correct HashedWheelBucket.
    long deadline = System.nanoTime() + unit.toNanos(delay) - startTime;
    // Guard against overflow.
    if (delay > 0 && deadline < 0) {
        deadline = Long.MAX_VALUE;
    }
    HashedWheelTimeout timeout = new HashedWheelTimeout(this, task, deadline);
    // 把任务添加到 queue 中
    // 到这里好像定时任务并没有被添加到 HashedWheelBucket 中 ？！
    // 不急具体的操作 Worker 的 run 方法中
    timeouts.add(timeout);
    return timeout;
}

// 这里简单的说下 start 的过程
// 使用 volatile 变量 来标记线程是否已经启动了
public void start() {
    switch (WORKER_STATE_UPDATER.get(this)) {
        case WORKER_STATE_INIT:
            if (WORKER_STATE_UPDATER.compareAndSet(this, WORKER_STATE_INIT, WORKER_STATE_STARTED)) {
                workerThread.start();
            }
            break;
        case WORKER_STATE_STARTED:
            break;
        case WORKER_STATE_SHUTDOWN:
            throw new IllegalStateException("cannot be started once stopped");
        default:
            throw new Error("Invalid WorkerState");
    }
    // Wait until the startTime is initialized by the worker.
    while (startTime == 0) {
        try {
            // 等待线程启动后执行 startTimeInitialized.countDown();
            // 这样后续才会执行后续的 add 条件定时任务
            startTimeInitialized.await();
        } catch (InterruptedException ignore) {
            // Ignore - it will be ready very soon.
        }
    }
}
```

## Worker

`Worker` 实现了 `Runnable`,核心逻辑在 `run` 方法中

```java
@Override
public void run() {
    // Initialize the startTime.
    startTime = System.nanoTime();// nanoTime 是虚拟机启动之后经历的时间
    if (startTime == 0) {
        // 在添加任务的时候，会判断 startTime 是否是0，如果不是
        // 则认为线程还没开始，就执行 startTimeInitialized.await() 进行等待
        // We use 0 as an indicator for the uninitialized value here, so make sure it's not 0 when initialized.
        startTime = 1;
    }
    // Notify the other threads waiting for the initialization at start().
    startTimeInitialized.countDown();
    do {
        final long deadline = waitForNextTick();
        if (deadline > 0) {// 大于0说明是正常的线程唤醒
            int idx = (int) (tick & mask);// 计算索引
            processCancelledTasks();// 处理取消的任务，就是把 cancelledTimeouts 中的任务删除了
            HashedWheelBucket bucket =
                    wheel[idx];
            transferTimeoutsToBuckets();// 把新增的任务放入到 bucket 中
            bucket.expireTimeouts(deadline);// 执行bucket 中的任务
            tick++;
        }
    } while (WORKER_STATE_UPDATER.get(HashedWheelTimer.this) == WORKER_STATE_STARTED);
    // 下面的方法只有在定时器停止的时候，才会执行
    // Fill the unprocessedTimeouts so we can return them from stop() method.
    for (HashedWheelBucket bucket : wheel) {
        bucket.clearTimeouts(unprocessedTimeouts);
    }
    for (; ; ) {
        HashedWheelTimeout timeout = timeouts.poll();
        if (timeout == null) {
            break;
        }
        if (!timeout.isCancelled()) {
            unprocessedTimeouts.add(timeout);
        }
    }
    processCancelledTasks();
}

// tick=滴答,像机械时钟一样，每次秒钟针走一次就是tick一次
// tickDuration=tick 的周期
// tick=tick 的次数
private long waitForNextTick() {
    // 计算下一次 tick 的时间
    long deadline = tickDuration * (tick + 1);
    for (; ; ) {
        final long currentTime = System.nanoTime() - startTime;
        // 转化成毫秒
        long sleepTimeMs = (deadline - currentTime + 999999) / 1000000;
        if (sleepTimeMs <= 0) {// 小于0说明时间到了，不需要睡眠
            if (currentTime == Long.MIN_VALUE) {
                return -Long.MAX_VALUE;
            } else {
                return currentTime;
            }
        }
        if (isWindows()) {
            sleepTimeMs = sleepTimeMs / 10 * 10;
        }
        try {
            Thread.sleep(sleepTimeMs);// 进行睡眠
        } catch (InterruptedException ignored) {
            if (WORKER_STATE_UPDATER.get(HashedWheelTimer.this) == WORKER_STATE_SHUTDOWN) {
                return Long.MIN_VALUE;
            }
        }
    }
}

// 把 timeouts 队列中的任务放入到 bucket 中
// 根据 deadline 和 tickDuration 来计算任务在
// bucket 中的位置
private void transferTimeoutsToBuckets() {
    // transfer only max. 100000 timeouts per tick to prevent a thread to stale the workerThread when it just
    // adds new timeouts in a loop.
    for (int i = 0; i < 100000; i++) {
        // 从 timeouts 中 获取任务
        HashedWheelTimeout timeout = timeouts.poll();
        if (timeout == null) {
            // all processed
            break;
        }
        if (timeout.state() == HashedWheelTimeout.ST_CANCELLED) {
            // Was cancelled in the meantime.
            // 任务取消了，不执行
            continue;
        }
        // 下面的代码整体思路是根据 deadline,tickDuration,tick,wheel
        // 来确定当前的这个定时任务的在 bucket 合适的位置
        // long deadline = System.nanoTime() + unit.toNanos(delay) - startTime;
        long calculated = timeout.deadline / tickDuration;
        // 根据 deadline 和已经 tick 的次数，计算剩余剩下的tick 次数
        // remainingRounds = 根据剩余的 tick 次数，计算出剩余的 tick 回合(一轮)
        timeout.remainingRounds = (calculated - tick) / wheel.length;
        // Ensure we don't schedule for past.
        // 第一种：calculated =200 tick=100 // remainingRounds=100
        // 第二种：calculated =200 tick=300 // remainingRounds=-100 这种情况定时任务需要马上触发了
        // 这里对第二种进行说明：
        // 如果remainingRounds=-100，ticks=tick=300
        // 也就是把定时任务加入倒当前300的位置，在执行 expireTimeouts 进行触发
        final long ticks = Math.max(calculated, tick);
        // 计算出定时任务在 bucket 的位置
        // mask 默认是 511
        // ticks & mask 结果是在 0-511 之间,相当于计算索引
        int stopIndex = (int) (ticks & mask);
        HashedWheelBucket bucket = wheel[stopIndex];
        bucket.addTimeout(timeout);// 加入 bucket
    }
}
// 执行到期的任务
void expireTimeouts(long deadline) {
     HashedWheelTimeout timeout = head;// head
     // process all timeouts
     while (timeout != null) {
         // 从链表的头开始
         HashedWheelTimeout next = timeout.next;
         if (timeout.remainingRounds <= 0) {// 小于0，删除任务，触发任务
             next = remove(timeout);
             if (timeout.deadline <= deadline) {
                 timeout.expire();// 执行任务
             } else {
                 // The timeout was placed into a wrong slot. This should never happen.
                 throw new IllegalStateException(String.format(
                         "timeout.deadline (%d) > deadline (%d)", timeout.deadline, deadline));
             }
         } else if (timeout.isCancelled()) {
             next = remove(timeout);
         } else {
             timeout.remainingRounds--;
         }
         timeout = next;
     }
}
// expire 执行到期的任务
// HashedWheelTimer#HashedWheelTimeout#expire
public void expire() {
    if (!compareAndSetState(ST_INIT, ST_EXPIRED)) {
        return;
    }
    try {
        task.run(this);// 执行任务
    } catch (Throwable t) {
        if (logger.isWarnEnabled()) {
            logger.warn("An exception was thrown by " + TimerTask.class.getSimpleName() + '.', t);
        }
    }
}
```
