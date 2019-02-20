# CyclicBarrier

字面意思：循环的栏栅

## docs

A synchronization aid that allows a set of threads to all wait for
each other to reach a common barrier point. `CyclicBarriers` are
useful in programs involving a fixed sized party of threads that
must occasionally wait for each other. The barrier is called
`cyclic` because it can be re-used after the waiting threads
are released.

## demo

```java
/**
 * desc: 模拟一个4人斗地主的场景，4个人都到了，斗地主开始
 */
public class CyclicBarrierDemo {
    public static void main(String[] args) {

        CyclicBarrier cyclicBarrier = new CyclicBarrier(4, () -> System.out.println("开始斗地主 ..."));

        IntStream.range(0, 4).forEach(i -> new Thread(() -> {
            try {
                System.out.println("等待开局 ..." + i);
                cyclicBarrier.await(1, TimeUnit.SECONDS);
                System.out.println("斗地主开始了 ..." + i);
            } catch (InterruptedException | BrokenBarrierException | TimeoutException e) {
                e.printStackTrace();
            }
        }).start());

    }
}
```

```log
等待开局 ...1
等待开局 ...0
等待开局 ...3
等待开局 ...2
开始斗地主 ...
斗地主开始了 ...2
斗地主开始了 ...1
斗地主开始了 ...0
斗地主开始了 ...3
```

## init

```java
    // 4 个人（线程）到达之后，会打印 开始斗地主
    CyclicBarrier cyclicBarrier = new CyclicBarrier(4, () -> System.out.println("开始斗地主 ..."));

    // CyclicBarrier 的成员变量

    /** The lock for guarding barrier entry */
    private final ReentrantLock lock = new ReentrantLock();// 锁控制并发
    /** Condition to wait on until tripped */
    private final Condition trip = lock.newCondition();// 控制线程的阻塞，唤醒
    /** The number of parties */
    private final int parties;// 斗地主需要的人数,这里是 4，这个值在初始化之后不会改变
    /* The command to run when tripped */
    private final Runnable barrierCommand;// 4 人到期之后执行的任务
    /** The current generation */
    private Generation generation = new Generation();// 可以理解为一个版本号

    /**
     * Number of parties still waiting. Counts down from parties to 0
     * on each generation.  It is reset to parties on each new
     * generation or when broken.
     */
    private int count;//这个值会不断减少
```

## await

```java
    public int await() throws InterruptedException, BrokenBarrierException {
        try {
            return dowait(false, 0L);// 具体逻辑在 dowait 方法中
        } catch (TimeoutException toe) {
            throw new Error(toe); // cannot happen
        }
}

private int dowait(boolean timed, long nanos)
        throws InterruptedException, BrokenBarrierException,
               TimeoutException {
        final ReentrantLock lock = this.lock;// 加锁
        lock.lock();
        try {
            final Generation g = generation;// 获取当前这一代信息

            if (g.broken)// 如果已经中断端了，结束
                throw new BrokenBarrierException();

            if (Thread.interrupted()) {
                breakBarrier();
                throw new InterruptedException();
            }

            int index = --count;
            if (index == 0) {  // tripped
                boolean ranAction = false;
                try {
                    final Runnable command = barrierCommand;
                    if (command != null)
                        command.run();
                    ranAction = true;
                    nextGeneration();
                    return 0;
                } finally {
                    if (!ranAction)
                        breakBarrier();
                }
            }

            // loop until tripped, broken, interrupted, or timed out
            for (;;) {
                try {
                    if (!timed)
                        trip.await();
                    else if (nanos > 0L)
                        nanos = trip.awaitNanos(nanos);
                } catch (InterruptedException ie) {
                    if (g == generation && ! g.broken) {
                        breakBarrier();
                        throw ie;
                    } else {
                        // We're about to finish waiting even if we had not
                        // been interrupted, so this interrupt is deemed to
                        // "belong" to subsequent execution.
                        Thread.currentThread().interrupt();
                    }
                }

                if (g.broken)
                    throw new BrokenBarrierException();

                if (g != generation)
                    return index;

                if (timed && nanos <= 0L) {
                    breakBarrier();
                    throw new TimeoutException();
                }
            }
        } finally {
            lock.unlock();// 释放锁
        }
    }
```

## reset

```java
    public void reset() {
        final ReentrantLock lock = this.lock;
        lock.lock();
        try {
            breakBarrier();   // break the current generation
            nextGeneration(); // start a new generation
        } finally {
            lock.unlock();
        }
    }
```