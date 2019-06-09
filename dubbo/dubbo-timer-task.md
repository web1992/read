# dubbo TimerTask

- [dubbo TimerTask](#dubbo-timertask)
  - [interface](#interface)
  - [Timer](#timer)
  - [HashedWheelTimer](#hashedwheeltimer)
  - [TimerTask](#timertask)
  - [Timeout](#timeout)
  - [HashedWheelTimeout](#hashedwheeltimeout)
  - [HashedWheelBucket](#hashedwheelbucket)
  - [Worker](#worker)

`dubbo` 定时任务的实现，来自于 `Netty` 的源码

## interface

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

// 获取等待的时间
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
        if (sleepTimeMs <= 0) {// 小于0说明时间到了，开始执行任务
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
        long calculated = timeout.deadline / tickDuration;
        // 根据 deadline 和已经 tick 的次数，计算剩余剩下的tick 次数
        // remainingRounds = 根据剩余的 tick 次数，计算出剩余的 tick 回合(一轮)
        timeout.remainingRounds = (calculated - tick) / wheel.length;
        // Ensure we don't schedule for past.
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
     HashedWheelTimeout timeout = head;
     // process all timeouts
     while (timeout != null) {
         HashedWheelTimeout next = timeout.next;
         if (timeout.remainingRounds <= 0) {
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
