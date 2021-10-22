# HashWheelTimer

## newTimeout

新增定时任务的时间复杂度 O(1)

```java
public Timeout newTimeout(TimerTask task, long delay, TimeUnit unit) {

     start();// 启动现在

     // Add the timeout to the timeout queue which will be processed on the next tick.
     // During processing all the queued HashedWheelTimeouts will be added to the correct HashedWheelBucket.
     long deadline = System.nanoTime() + unit.toNanos(delay) - startTime;

     // 包装成 HashedWheelTimeout 放入到 queue 中
     HashedWheelTimeout timeout = new HashedWheelTimeout(this, task, deadline);
     // private final Queue<HashedWheelTimeout> timeouts = PlatformDependent.newMpscQueue();
     timeouts.add(timeout);// 只是把任务放入到 queue 队列中，通过 transferTimeoutsToBuckets 异步扫描+执行任务
     return timeout;
 }

```

## Worker

`Worker` 线程中 `run` 方法是核心，读懂了此方法，就读懂了 `HashWheelTimer` 的实现。

1. 计算 deadline (线程此时可能休眠)
2. 把 TimeTask 从 queue 中移动到 bucket（bucke t 就是时间轮数组）
3. 根据 deadline ，执行到期的任务

```java
// 检查超时的核心在 Worker run 方法中
private final class Worker implements Runnable {

  private long tick;

  public void run() {
    do {
        final long deadline = waitForNextTick();// 计算 deadline
        if (deadline > 0) {
            // mask = wheel.length - 1;
            int idx = (int) (tick & mask);// 计算下一个 Bucket
            processCancelledTasks();// 处理那些取消的任务
            HashedWheelBucket bucket = wheel[idx];// 根据 idx 找到 bucket
            transferTimeoutsToBuckets();// 把 queue 中的数据，放到合适的 bucket 中
            bucket.expireTimeouts(deadline);// 处理 bucket 中到期的定时任务
            tick++;// tick 次数+1
        }
    } while (WORKER_STATE_UPDATER.get(HashedWheelTimer.this) == WORKER_STATE_STARTED);
  }


  // 每次循环1万次
  private void transferTimeoutsToBuckets() {
      // transfer only max. 100000 timeouts per tick to prevent a thread to stale the workerThread when it just
      // adds new timeouts in a loop.
      for (int i = 0; i < 100000; i++) {
          // Queue<HashedWheelTimeout> timeouts
          HashedWheelTimeout timeout = timeouts.poll();
          if (timeout == null) {
              // all processed
              break;
          }
          if (timeout.state() == HashedWheelTimeout.ST_CANCELLED) {
              // Was cancelled in the meantime.
              continue;
          }
          // long deadline = System.nanoTime() + unit.toNanos(delay) - startTime;
          long calculated = timeout.deadline / tickDuration;
          timeout.remainingRounds = (calculated - tick) / wheel.length;
          final long ticks = Math.max(calculated, tick); // Ensure we don't schedule for past.
          int stopIndex = (int) (ticks & mask);// mask = wheel.length - 1;
          HashedWheelBucket bucket = wheel[stopIndex];
          bucket.addTimeout(timeout);
      }
  }
}
```

`HashedWheelBucket#expireTimeouts` 方法，遍历链表，处理到期的任务

```java
/**
 * Expire all {@link HashedWheelTimeout}s for the given {@code deadline}.
 */
public void expireTimeouts(long deadline) {
    HashedWheelTimeout timeout = head;
    // process all timeouts
    while (timeout != null) {// 遍历链表
        HashedWheelTimeout next = timeout.next;
        if (timeout.remainingRounds <= 0) {// 1. round 小于等于0，任务到期，执行任务
            next = remove(timeout);
            if (timeout.deadline <= deadline) {
                timeout.expire();// 执行任务
            } else {
                // The timeout was placed into a wrong slot. This should never happen.
                throw new IllegalStateException(String.format(
                        "timeout.deadline (%d) > deadline (%d)", timeout.deadline, deadline));
            }
        } else if (timeout.isCancelled()) {// 2. 任务如果取消了，删除任务
            next = remove(timeout);
        } else {
            timeout.remainingRounds --;// 3. 其他情况 round 减一
        }
        timeout = next;
    }
}
```
