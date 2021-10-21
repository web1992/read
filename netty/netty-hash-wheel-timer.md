# HashWheelTimer

## Worker

```java
// 检查超时的核心在 Worker run 方法中
private final class Worker implements Runnable {

  // private long tick;

  public void run() {
    do {
        final long deadline = waitForNextTick();
        if (deadline > 0) {
            // mask = wheel.length - 1;
            int idx = (int) (tick & mask);// 计算下一个 Bucket
            processCancelledTasks();// 处理那些取消的任务
            HashedWheelBucket bucket = wheel[idx];// 根据 idx 找到bucket
            transferTimeoutsToBuckets();
            bucket.expireTimeouts(deadline);
            tick++;
        }
    } while (WORKER_STATE_UPDATER.get(HashedWheelTimer.this) == WORKER_STATE_STARTED);
  }


  // 每次 循环1万次
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
          long calculated = timeout.deadline / tickDuration;
          timeout.remainingRounds = (calculated - tick) / wheel.length;
          final long ticks = Math.max(calculated, tick); // Ensure we don't schedule for past.
          int stopIndex = (int) (ticks & mask);
          HashedWheelBucket bucket = wheel[stopIndex];
          bucket.addTimeout(timeout);
      }
  }
}

```
