# ThreadPool

- [ThreadPool](#threadpool)
  - [WrappedChannelHandler](#wrappedchannelhandler)
  - [FixedThreadPool](#fixedthreadpool)
  - [EagerThreadPool](#eagerthreadpool)
    - [TaskQueue](#taskqueue)
    - [EagerThreadPoolExecutor](#eagerthreadpoolexecutor)

`dubbo` 线程池的实现，主要作用是创建 `Executor`

已经有的实现类:

- FixedThreadPool
- CachedThreadPool
- LimitedThreadPool
- EagerThreadPool

| ThreadPool        | 特点                                                                                                                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| FixedThreadPool   | 核心线程数为 200，最大线程数是 200 ，固定大小的线程池,队列大小默认为 0，队列实现类是 SynchronousQueue                                                                                 |
| CachedThreadPool  | 核心线程数为 0，最大线程数是 Integer.MAX_VALUE，队列大小默认为 0，队列实现类是 SynchronousQueue，线程超过 1 分钟，没有使用，会被回收                                                  |
| LimitedThreadPool | 核心线程数为 0，最大线程数是 200,线程一直存活，队列大小默认为 0，队列实现类是 SynchronousQueue                                                                                        |
| EagerThreadPool   | 核心线程数为 0，最大线程数是 Integer.MAX_VALUE，队列大小默认为 0，队列实现类是 SynchronousQueue，线程超过 1 分钟，没有使用，会被回收(如果有任务，线程池会一直增加到Integer.MAX_VALUE) |

## WrappedChannelHandler

```java
// 线程池在创建 AllChannelHandler 对象是通过 super(handler, url); 创建，
public WrappedChannelHandler(ChannelHandler handler, URL url) {
    this.handler = handler;
    this.url = url;
    // 通过 SPI 扩展点加载线程池的实现
    // 默认是 FixedThreadPool
    executor = (ExecutorService) ExtensionLoader.getExtensionLoader(ThreadPool.class).getAdaptiveExtension().getExecutor(url);
    String componentKey = Constants.EXECUTOR_SERVICE_COMPONENT_KEY;
    if (Constants.CONSUMER_SIDE.equalsIgnoreCase(url.getParameter(Constants.SIDE_KEY))) {
        componentKey = Constants.CONSUMER_SIDE;
    }
    DataStore dataStore = ExtensionLoader.getExtensionLoader(DataStore.class).getDefaultExtension();
    dataStore.put(componentKey, Integer.toString(url.getPort()), executor);
}
```

## FixedThreadPool

```java
public class FixedThreadPool implements ThreadPool {

    @Override
    public Executor getExecutor(URL url) {
        // name 线程的名称 默认是 Dubbo
        // threads 线程池的线程数 默认是 200
        // queues 队列策略
        // queues==0 SynchronousQueue 同步队列
        // queues< 0 LinkedBlockingQueue 大小是 Integer.MAX_VALUE
        // 其他 指定大小 queue
        String name = url.getParameter(Constants.THREAD_NAME_KEY, Constants.DEFAULT_THREAD_NAME);
        int threads = url.getParameter(Constants.THREADS_KEY, Constants.DEFAULT_THREADS);
        int queues = url.getParameter(Constants.QUEUES_KEY, Constants.DEFAULT_QUEUES);
        return new ThreadPoolExecutor(threads, threads, 0, TimeUnit.MILLISECONDS,
                queues == 0 ? new SynchronousQueue<Runnable>() :
                        (queues < 0 ? new LinkedBlockingQueue<Runnable>()
                                : new LinkedBlockingQueue<Runnable>(queues)),
                new NamedInternalThreadFactory(name, true), new AbortPolicyWithReport(name, url));
    }

}
```

## EagerThreadPool

`EagerThreadPool` 实现的线程池

`TaskQueue` 重写了 `LinkedBlockingQueue` 的 `offer` 方法

`EagerThreadPoolExecutor` 重写了 `ThreadPoolExecutor` 的 `execute` 方法

```java
public class EagerThreadPool implements ThreadPool {

    @Override
    public Executor getExecutor(URL url) {
        // cores =  核心线程数，默认是 0
        // threads = 最大线程数，默认是 Integer.MAX_VALUE
        // queues 队列大小，默认是 0, queues <= 0 ? 1 : queues 但是有这个处理，任务队列默认大小是 1
        // alive 线程存活时间，默认是 60 秒
        String name = url.getParameter(Constants.THREAD_NAME_KEY, Constants.DEFAULT_THREAD_NAME);
        int cores = url.getParameter(Constants.CORE_THREADS_KEY, Constants.DEFAULT_CORE_THREADS);
        int threads = url.getParameter(Constants.THREADS_KEY, Integer.MAX_VALUE);
        int queues = url.getParameter(Constants.QUEUES_KEY, Constants.DEFAULT_QUEUES);
        int alive = url.getParameter(Constants.ALIVE_KEY, Constants.DEFAULT_ALIVE);

        // init queue and executor
        TaskQueue<Runnable> taskQueue = new TaskQueue<Runnable>(queues <= 0 ? 1 : queues);
        EagerThreadPoolExecutor executor = new EagerThreadPoolExecutor(cores,
                threads,
                alive,
                TimeUnit.MILLISECONDS,
                taskQueue,
                new NamedInternalThreadFactory(name, true),
                new AbortPolicyWithReport(name, url));
        taskQueue.setExecutor(executor);
        return executor;
    }
}
```

### TaskQueue

```java
@Override
public boolean offer(Runnable runnable) {
    if (executor == null) {
        throw new RejectedExecutionException("The task queue does not have executor!");
    }
    // 获取核心线程池的大小
    int currentPoolThreadSize = executor.getPoolSize();
    // have free worker. put task into queue to let the worker deal with task.
    // 如果有空闲的线程，提交任务到线程池
    if (executor.getSubmittedTaskCount() < currentPoolThreadSize) {
        return super.offer(runnable);
    }
    // return false to let executor create new worker.
    // 检查线程池的大小，如果小于最大的线程数限制,那么久返回 false
    // 相当于提交任务失败，那么就会使 ThreadPoolExecutor 创建新的线程数
    if (currentPoolThreadSize < executor.getMaximumPoolSize()) {
        return false;
    }
    // currentPoolThreadSize >= max
    // 当前线程数，超过最大线程数，提交任务到任务队列，可能成功，可能失败
    return super.offer(runnable);
}
/**
 * retry offer task
 *
 * @param o task
 * @return offer success or not
 * @throws RejectedExecutionException if executor is terminated.
 */
public boolean retryOffer(Runnable o, long timeout, TimeUnit unit) throws InterruptedException {
    if (executor.isShutdown()) {
        throw new RejectedExecutionException("Executor is shutdown!");
    }
    return super.offer(o, timeout, unit);
}
```

### EagerThreadPoolExecutor

```java
@Override
public void execute(Runnable command) {
    if (command == null) {
        throw new NullPointerException();
    }
    // do not increment in method beforeExecute!
    submittedTaskCount.incrementAndGet();
    try {
        super.execute(command);
    } catch (RejectedExecutionException rx) {
        // retry to offer the task into queue.
        // 如果提交任务失败，捕获异常
        // 再次提交任务，如果再次提交任务失败，则抛出异常
        final TaskQueue queue = (TaskQueue) super.getQueue();
        try {
            if (!queue.retryOffer(command, 0, TimeUnit.MILLISECONDS)) {
                submittedTaskCount.decrementAndGet();
                throw new RejectedExecutionException("Queue capacity is full.", rx);
            }
        } catch (InterruptedException x) {
            submittedTaskCount.decrementAndGet();
            throw new RejectedExecutionException(x);
        }
    } catch (Throwable t) {
        // decrease any way
        submittedTaskCount.decrementAndGet();
        throw t;
    }
}
```