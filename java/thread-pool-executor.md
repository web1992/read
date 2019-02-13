# ThreadPoolExecutor

> 目录

- [ThreadPoolExecutor](#threadpoolexecutor)
  - [类图](#%E7%B1%BB%E5%9B%BE)
  - [设计目的](#%E8%AE%BE%E8%AE%A1%E7%9B%AE%E7%9A%84)
  - [构造参数](#%E6%9E%84%E9%80%A0%E5%8F%82%E6%95%B0)
    - [Core and maximum pool sizes](#core-and-maximum-pool-sizes)
    - [On-demand construction](#on-demand-construction)
    - [Creating new threads](#creating-new-threads)
    - [Keep-alive times](#keep-alive-times)
    - [Queuing](#queuing)
      - [SynchronousQueue](#synchronousqueue)
      - [LinkedBlockingQueue](#linkedblockingqueue)
      - [ArrayBlockingQueue](#arrayblockingqueue)
    - [Rejected tasks](#rejected-tasks)
    - [Rejected demo](#rejected-demo)
  - [Hook methods](#hook-methods)
  - [Queue maintenance](#queue-maintenance)
  - [Finalization](#finalization)
  - [Method List](#method-list)
    - [runWorker](#runworker)
  - [Executors](#executors)
  - [参考](#%E5%8F%82%E8%80%83)

## 类图

![ThreadPoolExecutor](./images/ThreadPoolExecutor.png)

## 设计目的

- 执行异步任务(主要)
- 维护线程资源
- 统计信息

## 构造参数

### Core and maximum pool sizes

线程池大小策略

| 线程数                                                         | 策略         |
| -------------------------------------------------------------- | ------------ |
| 当前线程数 < `corePoolSize`                                    | 创建新的线程 |
| `corePoolSize`  < 当前线程数 < `maximumPoolSize` & queue.isFll | 创建新的线程 |
| `corePoolSize` = `maximumPoolSize`                             | 线程固定大小 |

### On-demand construction

默认情况下，只有当任务提交到了，才会创建线程，当然可以改变这个规则。

### Creating new threads

thread 构造策略,使用`ThreadFactory`来指定线程的Group,名称，优先级等其他设置

### Keep-alive times

线程存活策略,如果一个线程在`Keep-alive times`内没有被使用，则被会被销毁

### Queuing

队列策略

| case                      | action                                                                                                                                                                                    |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| pool size < corePoolSize  | adding a new thread       创建新的线程                                                                                                                                                    |
| pool size >= corePoolSize | queuing a request    进入队列                                                                                                                                                             |
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

有边界的队列，队列的大小和线程池的大小会相互影响，如果使用大队列&小线程池组合，可以减少 CPU,OS 资源的使用，线程切换，但是也可能导致低的吞吐量，如：任务经常阻塞(CPU一直在睡觉，CPU 得不到充分的利用)。
如果使用小队列&大线程池组合，那么 CPU 会频繁的进行线程切换(CPU 都在进行线程切换了，没时间做其他事情了)，也会导致吞吐量的下降。

### Rejected tasks

| policy                                 | action                                                                 |
| -------------------------------------- | ---------------------------------------------------------------------- |
| ThreadPoolExecutor.AbortPolicy         | the handler throws a runtime RejectedExecutionException upon rejection |
| ThreadPoolExecutor.CallerRunsPolicy    | the thread that invokes execute itself runs the task                   |
| ThreadPoolExecutor.DiscardPolicy       | a task that cannot be executed is simply dropped                       |
| ThreadPoolExecutor.DiscardOldestPolicy | the task at the head of the work queue is dropped                      |

异常策略，当Queuing有边界时(如果queue是没有边界的则不会触发)，超过queue大小的任务，如何处理

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

## Queue maintenance

Method `getQueue()` 为了调试设计,其他忽用

## Finalization

如果大量的线程，长时间的不使用，需要进行回收，否则就会浪费不必要的资源。或者忘记调用 `shutdown()` 方法进行关闭时，也会造成资源的浪费.

## Method List

### runWorker

我们知道如果 `ThreadPoolExecutor` 不执行 `shutdown` 方法，JVM 就不会退出，原因就在与 `runWorker` 中的 会区调用 `getTask` 方法，而 `getTask` 方法会调用 `BlockingQueue` 的 `take` 方法，（调用 `take` 方法时，如果队列中没有元素，那么该线程会一种阻塞，直到有数据放入队列），这就是 `ThreadPoolExecutor` 启动的线程池，不会主动关闭

`Worker` 类实现了 `Runnable` 接口，因此可以提交给线程进行执行，当执行 Thread#start 方法，线程启动之后，就执行 run 方法，从而执行 runWorker 方法

Worker 的 run 方法

```java
public void run() {
    runWorker(this);
}
```

而 `Thread#start` 是在 `addWorker` 方法中执行的

## Executors

`Executors` 中一些常用方法的说明，如果理解这些方法的`作用`和`不同点`，可以避免使用中的坑

如 `newFixedThreadPool` 和 `newSingleThreadExecutor`都使用  `LinkedBlockingQueue` 来存储多余的任务

如果线程处理的速度小于任务创建的速度，那么无法处理的任务都会放入 `Queue` 中,随着队列的无限增大会导致内存资源耗尽

下面 `Executors` 提供的几个方法，底层的Queue都是没有边界的，使用时候请注意内存泄露

`ThreadPoolExecutor` 使用 `BlockingQueue` 来存储多余的任务，那为什么不使用`ArrayList`,`LinkedList`呢？

> `ArrayList`,`LinkedList` 不是线程安全，如过使用这些来存储任务，会增加API的设计难度，而 `BlockingQueue` 天生为多线程而生

- 创建固定大小的线程池

```java
public static ExecutorService newFixedThreadPool(int nThreads) {
        return new ThreadPoolExecutor(nThreads, nThreads,
                                      0L, TimeUnit.MILLISECONDS,
                                      new LinkedBlockingQueue<Runnable>());
}
```

- 创建一个只包含一个线程的线程池

```java
public static ExecutorService newSingleThreadExecutor() {
        return new FinalizableDelegatedExecutorService
            (new ThreadPoolExecutor(1, 1,
                                    0L, TimeUnit.MILLISECONDS,
                                    new LinkedBlockingQueue<Runnable>()));
}
```

- newCachedThreadPool

如果没有可以使用的线程，就创建新的，如果有则复用之前的线程
如果一个线程在60秒内没有被使用，则被从cache中删除

```java
public static ExecutorService newCachedThreadPool() {
        return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                      60L, TimeUnit.SECONDS,
                                      new SynchronousQueue<Runnable>());
}
```

可以看到 上面的二个方法都使用`LinkedBlockingQueue`作用queue，那么为什么不使用`ArrayBlockingQueue`呢？

使用两个锁来控制线程访问，这样队列可以同时进行put和take的操作，因此吞吐量相对ArrayBlockingQueue就高

可参考 [queue](queue.md#LinkedBlockingQueue)

## 参考

- [ArrayList vs LinkedList](https://github.com/web1992/read/blob/master/java/list.md)
- [from oracle](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ThreadPoolExecutor.html)
- [draw.io file](./draw.io/ThreadPoolExecutor.xml)