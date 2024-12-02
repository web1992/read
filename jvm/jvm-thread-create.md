# JVM 线程创建 

## 线程创建


> java 中 Thread 如果线程没有正确的处理 InterruptedException 信号，会导致线程在 kill -15 之后无法正常退出吗


在 Java 中，如果一个线程没有正确处理 InterruptedException 信号，确实可能导致线程在发送 kill -15 (即 SIGTERM 信号) 后无法正常退出，但这是具体场景下的可能情况，而非普遍现象。

背景知识
kill -15 和应用程序退出：

kill -15 发送的是 SIGTERM 信号。大多数 JVM 会将该信号解释为请求安全退出。通常，JVM 会启动正常的关闭流程，例如调用已注册的 ShutdownHook，等待非守护线程退出等。
如果某些线程长时间阻塞或没有响应中断信号，JVM 的关闭流程可能会被延迟甚至卡住。
InterruptedException：

当线程处于阻塞状态（如调用 Thread.sleep()、wait()、join() 等方法）时，如果线程被中断，会抛出 InterruptedException，以通知线程应该考虑退出或完成中断逻辑。
如果线程忽略了这个异常，或未能正确处理中断请求，可能导致线程继续运行，阻碍 JVM 的正常退出。
为什么线程没有正确处理中断会导致问题？
阻塞状态的线程：

如果线程正在调用阻塞操作，例如 Thread.sleep() 或 Object.wait()，且这些操作抛出了 InterruptedException，但线程未捕获异常或未退出，那么线程会继续运行。
这样，JVM 在收到 SIGTERM 时会尝试等待所有非守护线程结束。如果这些线程未响应中断信号并持续运行，JVM 将无法完全退出。
轮询或繁忙等待的线程：

如果线程没有调用会自动检测中断状态的方法（如 sleep、wait、join），并且代码中没有检查线程的中断状态 (Thread.interrupted() 或 isInterrupted())，线程不会意识到它被中断了，从而继续运行。
Shutdown Hook 的干扰：

如果 ShutdownHook 本身存在问题，例如死锁或长时间运行的线程，可能导致 JVM 的退出被卡住。
如何正确处理中断信号？
检查中断状态： 在非阻塞代码中，定期检查 Thread.currentThread().isInterrupted()，并做出适当响应（例如清理资源并退出）。

正确处理 InterruptedException： 捕获 InterruptedException 后，除了必要的资源清理外，通常应该重新设置中断状态：

```java
try {
    Thread.sleep(1000);
} catch (InterruptedException e) {
    // 恢复中断状态
    Thread.currentThread().interrupt();
    // 退出线程
    return;
}

```
设置守护线程： 如果线程是后台辅助任务，考虑将其设置为守护线程（通过 thread.setDaemon(true)），这样 JVM 在收到 SIGTERM 后不会等待守护线程。

使用 Executor 框架： 使用 ExecutorService 管理线程，调用 shutdownNow() 方法可以优雅地终止线程池中的线程（它会尝试中断正在运行的线程）。

总结
如果线程忽略了中断信号或没有正确处理 InterruptedException，可能会阻碍 JVM 在收到 kill -15 时的正常退出。这种情况下，建议通过以下方式解决：

捕获并正确处理中断信号。
定期检查中断状态。
避免阻塞操作或繁忙等待。
必要时设置线程为守护线程。
通过这些方式可以确保应用程序在接收到终止信号时能够优雅退出。


## jvm 里面的 守护线程 有什么特殊

1. 守护线程的核心特性：
JVM 退出行为： 如果一个 Java 应用程序中只剩下守护线程在运行，JVM 会自动退出，而无需等待守护线程完成任务。

换句话说，守护线程的生命周期依赖于 JVM 的生命周期。
当 JVM 退出时，所有正在运行的守护线程会被强制停止，且不会执行 finally 块或其他清理代码。
普通线程的退出规则： 普通线程（非守护线程）会阻止 JVM 退出，JVM 必须等所有普通线程执行完毕后才会退出。

2. 守护线程的典型用途：
守护线程通常用于执行后台支持任务，不需要显式的生命周期管理。例如：

垃圾收集器 (Garbage Collector)： JVM 的垃圾收集线程就是一个守护线程，它在后台回收未使用的内存。
其他后台任务： 守护线程常用于日志记录、性能监控、文件清理、数据库连接池管理等。
3. 如何设置线程为守护线程？
通过 Thread 类的 setDaemon(true) 方法可以将一个线程设置为守护线程：

```java
复制代码
Thread t = new Thread(() -> {
    while (true) {
        System.out.println("Daemon thread running...");
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
});
t.setDaemon(true); // 设置为守护线程
t.start();
```

注意：

必须在 start() 方法调用之前调用 setDaemon(true)，否则会抛出 IllegalThreadStateException。
默认情况下，线程是非守护线程。
4. 守护线程的清理问题：
因为 JVM 在退出时不会等待守护线程完成任务，所以守护线程可能会被突然中断，导致资源清理（如文件关闭、网络连接释放）无法完成。
如果守护线程需要执行资源清理逻辑，建议在主线程或普通线程中显式管理，而不是依赖 JVM 的强制终止。
5. 守护线程和普通线程的关系：
守护线程不会“独立运行”，它的存在意义在于为其他普通线程提供辅助服务。
如果某个普通线程创建了一个线程，那么这个线程会继承父线程的守护状态。如果父线程是守护线程，那么子线程也会自动变成守护线程。
6. 守护线程的限制：
守护线程在 JVM 强制终止时可能导致意外行为，因此不能用于需要可靠完成的任务。例如，数据库操作或文件保存通常不应由守护线程执行。
7. 守护线程示例：
普通线程和守护线程的对比：

```java
public class DaemonExample {
    public static void main(String[] args) {
        Thread daemonThread = new Thread(() -> {
            while (true) {
                System.out.println("Daemon thread running...");
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        });
        daemonThread.setDaemon(true); // 设置为守护线程
        daemonThread.start();

        Thread userThread = new Thread(() -> {
            System.out.println("User thread running...");
            try {
                Thread.sleep(2000); // 让主线程运行 2 秒后结束
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println("User thread finished.");
        });
        userThread.start();
    }
}

```

输出分析：

守护线程会持续打印 "Daemon thread running..."，直到主线程和所有普通线程结束。
当 userThread 和主线程都退出后，JVM 停止，守护线程会被强制中止。
总结：
守护线程的生命周期依赖 JVM，它主要服务于普通线程。
JVM 在只有守护线程运行时会直接退出，不会等待守护线程完成任务。
使用守护线程时要谨慎，避免它负责重要任务的清理或保存逻辑。