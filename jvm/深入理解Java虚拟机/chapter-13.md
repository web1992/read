## 第 13 章　线程安全与锁优化

- 线程安全
- 互斥同步
- 临界区（CriticalSection）
- 互斥量（Mutex）
- 信号量（Semaphore）
- synchronized 关键字
- monitorenter
- monitorexit
- ReentrantLock 可重入
- ReentrantLock 等待可中断
- ReentrantLock 公平锁
- ReentrantLock 绑定多个锁条件
- 基于冲突检测的乐观并发策略 CAS
- 锁优化 自旋锁与自适应锁
- 锁优化 锁消除
- 锁优化 锁粗化
- 锁优化 轻量级锁
- 锁优化 偏向锁

笔者认为《Java 并发编程实战（JavaConcurrencyInPractice）》的作者 BrianGoetz 为“线程安全”做出了一个比较恰当的定义：“当多个线程同时访问一个对象时，如果不用考虑这些线程在运行时环境下的调度和交替执行，也不需要进行额外的同步，或者在调用方进行任何其他的协调操作，调用这个对象的行为都可以获得正确的结果，那就称这个对象是线程安全的。”

## synchronized 关键字

根据《Java 虚拟机规范》的要求，在执行 monitorenter 指令时，首先要去尝试获取对
象的锁。如果这个对象没被锁定，或者当前线程已经持有了那个对象的锁，就把锁的计数器的值增加一，
而在执行 monitorexit 指令时会将锁计数器的值减一。一旦计数器的值为零，锁随即就被释放了。如果获取对象锁失败，那当前线程就应当被阻塞等待，直到请求锁定的对象被持有它的线程释放为止。
