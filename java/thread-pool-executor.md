# ThreadPoolExecutor

> 目录

- [ThreadPoolExecutor](#ThreadPoolExecutor)
  - [ExecutorService 类图](#ExecutorService-%E7%B1%BB%E5%9B%BE)
  - [设计目的](#%E8%AE%BE%E8%AE%A1%E7%9B%AE%E7%9A%84)
  - [构造参数](#%E6%9E%84%E9%80%A0%E5%8F%82%E6%95%B0)
    - [Core and maximum pool sizes](#Core-and-maximum-pool-sizes)
    - [On-demand construction](#On-demand-construction)
    - [Creating new threads](#Creating-new-threads)
    - [Keep-alive times](#Keep-alive-times)
    - [Queuing](#Queuing)
      - [SynchronousQueue](#SynchronousQueue)
      - [LinkedBlockingQueue](#LinkedBlockingQueue)
      - [ArrayBlockingQueue](#ArrayBlockingQueue)
    - [Rejected tasks](#Rejected-tasks)
    - [Rejected demo](#Rejected-demo)
  - [Hook methods](#Hook-methods)
  - [Queue maintenance](#Queue-maintenance)
  - [Finalization](#Finalization)
  - [runState](#runState)
  - [Method List](#Method-List)
    - [execute](#execute)
    - [runWorker](#runWorker)
    - [getTask](#getTask)
  - [Worker](#Worker)
  - [Executors](#Executors)
    - [newFixedThreadPool](#newFixedThreadPool)
    - [newSingleThreadExecutor](#newSingleThreadExecutor)
    - [newCachedThreadPool](#newCachedThreadPool)
  - [参考](#%E5%8F%82%E8%80%83)

## ExecutorService 类图

![ThreadPoolExecutor](./images/ThreadPoolExecutor.png)

## 设计目的

- 避免频繁的创建和销毁线程
- (周期性的)执行异步任务(主要)
- 维护线程资源
- 统计信息

周期性的执行任务，可参考这个 [scheduled-thread-pool-executor.md](scheduled-thread-pool-executor.md)

## 构造参数

### Core and maximum pool sizes

线程池大小策略

| 线程数                                                        | 策略         |
| ------------------------------------------------------------- | ------------ |
| 当前线程数 < `corePoolSize`                                   | 创建新的线程 |
| `corePoolSize` < 当前线程数 < `maximumPoolSize` & queue.isFll | 创建新的线程 |
| `corePoolSize` = `maximumPoolSize`                            | 线程固定大小 |

### On-demand construction

默认情况下，只有当任务提交到了，才会创建线程，当然可以改变这个规则。

### Creating new threads

thread 构造策略,使用 `ThreadFactory` 来指定线程的 Group,名称，优先级等其他设置

### Keep-alive times

线程存活策略,如果一个线程在 `Keep-alive times` 内没有被使用，则被会被销毁

### Queuing

队列策略

| case                      | action                                                                                                                                                                                    |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| pool size < corePoolSize  | adding a new thread 创建新的线程                                                                                                                                                          |
| pool size >= corePoolSize | queuing a request 进入队列                                                                                                                                                                |
| queue is full             | If a request cannot be queued, a new thread is created unless this would exceed maximumPoolSize, in which case, the task will be rejected. There are three general strategies for queuing |

> strategies for queuing

| strategy         | queue               |
| ---------------- | ------------------- |
| Direct handoffs  | SynchronousQueue    |
| Unbounded queues | LinkedBlockingQueue |
| Bounded queues   | ArrayBlockingQueue  |

#### SynchronousQueue

**Direct handoffs**. A good default choice for a work queue is a `SynchronousQueue` that hands off tasks to threads without otherwise holding them. Here, an attempt to queue a task will fail if no threads are immediately available to run it, so a new thread will be constructed. This policy avoids lockups when handling sets of requests that might have internal dependencies. Direct handoffs generally require unbounded `maximumPoolSizes` to avoid rejection of new submitted tasks. This in turn admits the possibility of unbounded thread growth when commands continue to arrive on average faster than they can be processed.

`SynchronousQueue`同步的队列

#### LinkedBlockingQueue

**Unbounded queues**. Using an unbounded queue (for example a `LinkedBlockingQueue` without a predefined capacity) will cause new tasks to wait in the queue when all corePoolSize threads are busy. Thus, no more than corePoolSize threads will ever be created. (And the value of the `maximumPoolSize` therefore doesn't have any effect.) This may be appropriate when each task is completely independent of others, so tasks cannot affect each others execution; for example, in a web page server. While this style of queuing can be useful in smoothing out transient bursts of requests, it admits the possibility of unbounded work queue growth when commands continue to arrive on average faster than they can be processed.

无边界的队列，同时也是有序的队列，（适应任务之间有依赖关系的场景）但是如果消费的速度小于生成的速度，会导致队列无限增加（最终可导致服务不可用）

#### ArrayBlockingQueue

**Bounded queues**. A bounded queue (for example, an `ArrayBlockingQueue`) helps prevent resource exhaustion when used with finite `maximumPoolSizes`, but can be more difficult to tune and control. Queue sizes and maximum pool sizes may be traded off for each other: Using large queues and small pools minimizes CPU usage, OS resources, and context-switching overhead, but can lead to artificially low throughput. If tasks frequently block (for example if they are I/O bound), a system may be able to schedule time for more threads than you otherwise allow. Use of small queues generally requires larger pool sizes, which keeps CPUs busier but may encounter unacceptable scheduling overhead, which also decreases throughput.

有边界的队列，队列的大小和线程池的大小会相互影响，如果使用`大队列`&`小线程池`组合，可以减少 CPU,OS 资源的使用，线程切换，但是也可能导致低的吞吐量，如：任务经常阻塞(CPU 一直在睡觉，CPU 得不到充分的利用)。
如果使用`小队列`&`大线程池`组合，那么 CPU 会频繁的进行线程切换(CPU 都在进行线程切换了，没时间做其他事情了)，也会导致吞吐量的下降。

### Rejected tasks

| policy                                 | action                                                                 |
| -------------------------------------- | ---------------------------------------------------------------------- |
| ThreadPoolExecutor.AbortPolicy         | the handler throws a runtime RejectedExecutionException upon rejection |
| ThreadPoolExecutor.CallerRunsPolicy    | the thread that invokes execute itself runs the task                   |
| ThreadPoolExecutor.DiscardPolicy       | a task that cannot be executed is simply dropped                       |
| ThreadPoolExecutor.DiscardOldestPolicy | the task at the head of the work queue is dropped                      |

异常策略，当 Queuing 有边界时(如果 queue 是没有边界的则不会触发)，超过 queue 大小的任务，如何处理

### Rejected demo

```java
public static void main(String[] args) throws InterruptedException {
        RejectedExecutionHandler reh = (Runnable r, ThreadPoolExecutor executor) -> {
            System.err.println("the task " + r.toString() + " is rejected ... poll status " + executor.toString());
        };
        // new LinkedBlockingDeque<>(2) // 有边界的queue
        ThreadPoolExecutor tpe = new ThreadPoolExecutor(5, 5, 1, TimeUnit.SECONDS, new LinkedBlockingDeque<>(2), reh);
        System.out.println(tpe.toString());
        IntStream.range(0, 10).forEach(
                index -> {
                    tpe.execute(() -> {
                        try {
                            TimeUnit.SECONDS.sleep(1L);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        System.out.println("run = " + index);
                    });
                }
        );

        System.out.println("end");
        System.out.println(tpe);
        tpe.shutdown();
    }
```

## Hook methods

钩子方法，可以在任务执行之前（之后），之后做一些操作，如：统计信息

- beforeExecute
- afterExecute
- onShutdown
- terminated

## Queue maintenance

Method `getQueue()` 为了调试设计,其他忽用

## Finalization

如果大量的线程，长时间的不使用，需要进行回收，否则就会浪费不必要的资源。或者忘记调用 `shutdown()` 方法进行关闭时，也会造成资源的浪费.

## runState

| state      | desc                                                                                                                           |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------ |
| RUNNING    | Accept new tasks and process queued tasks                                                                                      |
| SHUTDOWN   | Don't accept new tasks, but process queued tasks                                                                               |
| STOP       | Don't accept new tasks, don't process queued tasks,and interrupt in-progress tasks                                             |
| TIDYING    | All tasks have terminated, workerCount is zero,the thread transitioning to state TIDYING will run the terminated() hook method |
| TERMINATED | terminated() has completed                                                                                                     |

## Method List

### execute

```java
// execute 方法会根据当前线程池的状态，对任务进行不同的处理
// execute 与 submit 对比:
// execute 是 java.util.concurrent.Executor 中定义的方法
// submit  是 java.util.concurrent.ExecutorService 中定义的方法
// execute 返回值是 void
// submit 返回值是 Future
// submit 最终还是把任务给了 execute 进行执行的
// submit 支持异步的结果查询
public void execute(Runnable command) {
    if (command == null)
        throw new NullPointerException();
    /*
     * Proceed in 3 steps:
     *
     * 1. If fewer than corePoolSize threads are running, try to
     * start a new thread with the given command as its first
     * task.  The call to addWorker atomically checks runState and
     * workerCount, and so prevents false alarms that would add
     * threads when it shouldn't, by returning false.
     *
     * 2. If a task can be successfully queued, then we still need
     * to double-check whether we should have added a thread
     * (because existing ones died since last checking) or that
     * the pool shut down since entry into this method. So we
     * recheck state and if necessary roll back the enqueuing if
     * stopped, or start a new thread if there are none.
     *
     * 3. If we cannot queue task, then we try to add a new
     * thread.  If it fails, we know we are shut down or saturated
     * and so reject the task.
     */
    int c = ctl.get();
    // 1. 当前的线程数，小于核心线程数，创建线程
    if (workerCountOf(c) < corePoolSize) {
        if (addWorker(command, true))
            return;
        c = ctl.get();
    }
    // 2. 如果线程池没有关闭，任务进入 queue 成功
    if (isRunning(c) && workQueue.offer(command)) {
        int recheck = ctl.get();
        // 再次检查线程池是否关闭
        // 如果关闭了，删除任务（从 queue 中删除）
        // 如果删除任务成功，则执行 reject
        // (线程正在关闭&&从queue 中删除了，那么此任务就不会被执行了)
        if (!isRunning(recheck) && remove(command))
            reject(command);
        // 这里 worlerCont 判断其实不是必要的
        // 这里就是判断如果线程池中没有线程(线程池正在运行),就新增一个线程
        else if (workerCountOf(recheck) == 0)
            addWorker(null, false);
    }
    // 3. 线程池正在关闭 & 进入 queue 失败,就执行新增线程
    //   新增线程失败，触发 reject
    //   (addWorker 中有对线程池状态的判断) 这里没有执行线程只状态的检查
    else if (!addWorker(command, false))
        reject(command);
}
```

### runWorker

我们知道如果 通过 `newFixedThreadPool` 和 `newSingleThreadExecutor` 创建的 `ThreadPoolExecutor` 不执行 `shutdown` 方法，JVM 就不会退出，原因就在与 `runWorker` 中的 会区调用 `getTask` 方法，而 `getTask` 方法会调用 `BlockingQueue` 的 `take` 方法，（调用 `take` 方法时，如果队列中没有元素，那么该线程会一直阻塞，直到有数据放入队列），这就是 `newFixedThreadPool`& `newSingleThreadExecutor` 启动的线程池，不会主动关闭的原因

`newCachedThreadPool` 创建的线程池会，如果超过 60 秒没有可执行的任务，就会退出,原因在与会执行 `workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS)`

该方法只会阻塞 60 秒，如果过了 60 秒，还没任务可执行，会更新 `timedOut`变量的值，那么就会结束 `while` 循环，最终终止线程

`Worker` 类实现了 `Runnable` 接口，因此可以提交给线程进行执行，当执行 `Thread#start` 方法，线程启动之后，就执行 `run` 方法，从而执行 `runWorker` 方法

Worker 的 run 方法

```java
public void run() {
    runWorker(this);
}
```

而 `Thread#start` 是在 `addWorker` 方法中执行的

```java
// Worker 继承了 AbstractQueuedSynchronizer，实现锁的功能
final void runWorker(Worker w) {
    Thread wt = Thread.currentThread();
    Runnable task = w.firstTask;
    w.firstTask = null;
    w.unlock(); // allow interrupts
    boolean completedAbruptly = true;
    try {
        // getTask 是从 BlockingQueue 中获取数据的，如果没有数据，会一直阻塞
        // getTask 如果返回了 null ,那么 while 就不再次循环了，
        // 就会执行 finally 中的代码
        // getTask 中也会对可用的线程数 -1
        while (task != null || (task = getTask()) != null) {
            w.lock();// 加锁
            // If pool is stopping, ensure thread is interrupted;
            // if not, ensure thread is not interrupted.  This
            // requires a recheck in second case to deal with
            // shutdownNow race while clearing interrupt
            if ((runStateAtLeast(ctl.get(), STOP) ||
                 (Thread.interrupted() &&
                  runStateAtLeast(ctl.get(), STOP))) &&
                !wt.isInterrupted())
                wt.interrupt();
            try {
                beforeExecute(wt, task);// 钩子方法
                Throwable thrown = null;
                try {
                    task.run();// 执行任务
                } catch (RuntimeException x) {
                    thrown = x; throw x;
                } catch (Error x) {
                    thrown = x; throw x;
                } catch (Throwable x) {
                    thrown = x; throw new Error(x);
                } finally {
                    afterExecute(task, thrown);// 钩子方法
                }
            } finally {
                task = null;
                w.completedTasks++;
                w.unlock();// 释放锁
            }
        }
        completedAbruptly = false;
    } finally {
        // 这个 finally 块
        // 只有在调用了 getTask() 方法返回了 null 之后(while 循环会结束)
        // 才会执行关闭线程的操作
        // 具体的线程退出操作在 interruptIdleWorkers 中
        processWorkerExit(w, completedAbruptly);
    }
}
// 关闭线程，通过 t.interrupt(); 进行关闭线程
// onlyOne = true 一次只关闭一个线程
// interruptIdleWorkers 方法的逻辑就是从 workers 集合中查询找到一个 Worker
// 执行两个判断:
// 1. 判断线程是否执行了 interrupt 方法
//    如果执行过了，说明线程已经终止了，找下一个线程
// 2. 并尝试获取锁，如果获取锁成功，证明
//    这个线程没有正在执行的任务(空闲状态)
//    执行 t.interrupt(); 进行线程的退出
private void interruptIdleWorkers(boolean onlyOne) {
final ReentrantLock mainLock = this.mainLock;
mainLock.lock();
try {
    for (Worker w : workers) {
        Thread t = w.thread;
        if (!t.isInterrupted() && w.tryLock()) {
            try {
                t.interrupt();
            } catch (SecurityException ignore) {
            } finally {
                w.unlock();
            }
        }
        if (onlyOne)
            break;
    }
} finally {
    mainLock.unlock();
}
}
```

### getTask

```java
    // getTask 返回了null,那么这个线程就会退出
    // 有下面四种情况
    // 1. 线程数超过了 maximumPoolSize，返回 Null
    // 2. 线程池 stopped
    // 3. 线程池 shutdown & 队列为空
    // 4. 线程在执行的时间内，没有可执行任务，并且超过了 corePoolSize
    //    那么就会退出（如：keepAliveTime=10，说明此线程已经阻塞了10 纳秒，依然没有可以执行的任务，那么线程就退出）
    private Runnable getTask() {
        boolean timedOut = false; // Did the last poll() time out?

        for (;;) {
            int c = ctl.get();
            int rs = runStateOf(c);

            // Check if queue empty only if necessary.
            // 如果线程池正在关闭，或者任务队列为空，就返回空
            // 同时把可用的线程数 -1
            if (rs >= SHUTDOWN && (rs >= STOP || workQueue.isEmpty())) {
                decrementWorkerCount();
                return null;
            }

            int wc = workerCountOf(c);

            // Are workers subject to culling?
            boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;

            // 如果工作线程超过了配置的最大线程数，或者 允许超时&上一次任务超时了
            // 并且（工作的线程大于1 或者队列为空）
            // 就尝试进行线程的回收(减少)
            // 尝试成功，就返回 null,后续会执行 processWorkerExit 方法
            // 把 线程从 workers 集合中删除
            if ((wc > maximumPoolSize || (timed && timedOut))
                && (wc > 1 || workQueue.isEmpty())) {
                if (compareAndDecrementWorkerCount(c))
                    return null;
                continue;
            }

            try {
                // 如果允许线程超时，使用 poll 获取任务
                // 否则使用 take 一直阻塞到有任务进入队列
                Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
                    workQueue.take();
                if (r != null)
                    return r;
                timedOut = true;// 如果 r=null,就是在制定时间内，没有可执行的任务，就设置超时标记为 true
            } catch (InterruptedException retry) {
                timedOut = false;
            }
        }
    }
```

## Worker

```java
   // Worker 类是 ThreadPoolExecutor 的内部类
   // Worker 继承了 aqs 类，实现了一个不可重入的锁功能
   // Worker 实现锁功能的目的是为了方便终止线程(可参考 interruptIdleWorkers 方法)
   // 线程在执行任务的时候，会先加锁，执行完成之后，会释放锁
   // 在终止线程的时候，会使用 tryLock 去获取锁，如果获取锁成功
   // 说明此线程没有在执行任务，就使用 Thread#interrupt 方法终止线程，进行线程的回收
   // Worker 实现了 Runnable 实现了 run 方法
   // Worker 中维护一个 Thread
   private final class Worker
        extends AbstractQueuedSynchronizer
        implements Runnable
    {
        Worker(Runnable firstTask) {
            setState(-1); // inhibit interrupts until runWorker
            this.firstTask = firstTask;
            // 这里在创建 Thread 的时候把 Worker(Runnable) 给Thread
            // 当在执行 Thread#start 的之后，线程启动之后，会执行下面的 run 方法
            this.thread = getThreadFactory().newThread(this);
        }
        // 在线程启动之后，会执行 Worker 的 run 方法
        public void run() {
            runWorker(this);
        }
    }
```

## Executors

`Executors` 中一些常用方法的说明，如果理解这些方法的`作用`和`不同点`，可以避免使用中的坑

如 `newFixedThreadPool` 和 `newSingleThreadExecutor`都使用 `LinkedBlockingQueue` 来存储多余的任务

如果线程处理的速度小于任务创建的速度，那么无法处理的任务都会放入 `Queue` 中,随着队列的无限增大会导致内存资源耗尽

下面 `Executors` 提供的几个方法，底层的 Queue 都是没有边界的，使用时候请注意内存泄露

`ThreadPoolExecutor` 使用 `BlockingQueue` 来存储多余的任务，那为什么不使用`ArrayList`,`LinkedList`呢？

> `ArrayList`,`LinkedList` 不是线程安全，如过使用这些来存储任务，会增加 API 的设计难度，而 `BlockingQueue` 天生为多线程而生

### newFixedThreadPool

- 创建固定大小的线程池

```java
public static ExecutorService newFixedThreadPool(int nThreads) {
        return new ThreadPoolExecutor(nThreads, nThreads,
                                      0L, TimeUnit.MILLISECONDS,
                                      new LinkedBlockingQueue<Runnable>());
}
```

### newSingleThreadExecutor

- 创建一个只包含一个线程的线程池

```java
public static ExecutorService newSingleThreadExecutor() {
        return new FinalizableDelegatedExecutorService
            (new ThreadPoolExecutor(1, 1,
                                    0L, TimeUnit.MILLISECONDS,
                                    new LinkedBlockingQueue<Runnable>()));
}
```

### newCachedThreadPool

如果没有可以使用的线程，就创建新的，如果有则复用之前的线程
如果一个线程在 60 秒内没有被使用，则被从 cache 中删除&线程会被终止

```java
public static ExecutorService newCachedThreadPool() {
        return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                      60L, TimeUnit.SECONDS,
                                      new SynchronousQueue<Runnable>());
}
```

`newCachedThreadPool` 创建的线程会在 60 秒之后，进行终止，是因为在构造 `ThreadPoolExecutor` 时
`corePoolSize = 0` & `keepAliveTime=60`

```java
// 这里通过代码分析下实现原理
// newCachedThreadPool 在构造线程池的时候，下面的代码 corePoolSize =0
// wc 为线程数，只要有线程存在，那么 timed 就为 true
// keepAliveTime =60 秒，
// timed=ture 因此会执行 poll 从队列中获取任务，如果超过了60秒，没可执行的任务，
// 那么就返回 null,同时因为 poll 的阻塞，该线程也等待了60 秒（其实就是线程这60秒只顾睡觉了，什么都没做）
// 返回 null 之后，在后续的逻辑中，会进线程的终止 具体代码在 processWorkerExit 方法中

boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;

Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
                    workQueue.take();
                if (r != null)
                    return r;
```

`newCachedThreadPool` 创建的线程池会在线程闲置 60 之后销毁所有的线程(corePoolSize=0)，从而退出(不需要手动的调用 shutdown 方法)
而 `newFixedThreadPool` & `newSingleThreadExecutor` 创建的线程池(corePoolSize!=0)，由于始终存在一个或者多个线程
而这一个或者多个线程因为调用 `workQueue.take()` 会阻塞，因此不会退出(需要手动的调用 `shutdown` 方法)

可以看到 上面的二个方法都使用`LinkedBlockingQueue`作用 `queue`,那么为什么不使用`ArrayBlockingQueue`呢？

使用两个锁来控制线程访问，这样队列可以同时进行 `put` 和 `take` 的操作，因此吞吐量相对 `ArrayBlockingQueue` 就高

可参考 [queue](queue.md#LinkedBlockingQueue)

## 参考

- [ArrayList vs LinkedList](https://github.com/web1992/read/blob/master/java/list.md)
- [from oracle](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ThreadPoolExecutor.html)
- [draw.io file](./draw.io/ThreadPoolExecutor.xml)
