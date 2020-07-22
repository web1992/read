---
id: thread-pool-executor-constructor
title: ThreadPoolExecutor 之构造参数
author: web1992
author_title: web1992
author_url: https://github.com/web1992
author_image_url: https://avatars3.githubusercontent.com/u/6828647?s=60&v=4
tags: [java]
---

## ThreadPoolExecutor 之构造参数

ThreadPoolExecutor 提供了一系列的参数，用来方便的控制线程池的行为,下面进行解释

```java
// ThreadPoolExecutor 的构造参数
public ThreadPoolExecutor(
    int corePoolSize,
    int maximumPoolSize,
    long keepAliveTime,
    TimeUnit unit,
    BlockingQueue<Runnable> workQueue,
    ThreadFactory threadFactory,
    RejectedExecutionHandler handler) {

// ...
}
```

| 参数            | 类型                     | 含义                                                                                      |
| --------------- | ------------------------ | ----------------------------------------------------------------------------------------- |
| corePoolSize    | int                      | 核心线程数的大小(最小的线程数据)                                                          |
| maximumPoolSize | int                      | 最大线程数(线程数量不能超过这个)，当队列满了之后，会继续参加线程到 maximumPoolSize 个线程 |
| keepAliveTime   | long                     | 线程最大存活时间                                                                          |
| unit            | TimeUnit                 | 线程最大存活时间的时间单位                                                                |
| workQueue       | BlockingQueue            | 工作队列，用来存储多余的任务（当线程数超过corePoolSize，之后多余的任务就会放入队列中）    |
| threadFactory   | ThreadFactory            | 线程工厂，用来执行线程的名称，优先级等                                                    |
| handler         | RejectedExecutionHandler | 异常处理，通常在线程都在繁忙，并且队列满了之后触发的异常机制                              |

## 思考

虽然 `Executors` 提供了众多的方法来创建线程池，但是如果使用不当，可能引发风险

- 风险一：无限制的创建线程导致，机器资源耗尽，服务宕机,比如: `Executors.newCachedThreadPool`
- 风险二：没有限制`BlockingQueue`队列的大小，导致内存消耗过大，比如: `Executors.newFixedThreadPool`

因此建议最佳实践是自己创建 `ThreadPoolExecutor` 根据不同的场景进行不同的参数设置

比如 `Dubbo` 中 固定线程池的实现：

```java
public class FixedThreadPool implements ThreadPool {

    @Override
    public Executor getExecutor(URL url) {
        String name = ...
        int threads = ...
        int queues = ...
        return new ThreadPoolExecutor(threads, threads, 0, TimeUnit.MILLISECONDS,
                queues == 0 ? new SynchronousQueue<Runnable>() :
                        (queues < 0 ? new LinkedBlockingQueue<Runnable>()
                                : new LinkedBlockingQueue<Runnable>(queues)),
                new NamedInternalThreadFactory(name, true), new AbortPolicyWithReport(name, url));
    }

}
```

- corePoolSize 与 maximumPoolSize 相等，含义是线程池在创建之后，到达 maximumPoolSize，大小就不会改变了
- 由于 corePoolSize=maximumPoolSize 线程池大小不变，因此存活时间设置没有意义，这里设置成0
- SynchronousQueue 同步队列，可以认为是一次只能存放一个任务的队列，比较常用
