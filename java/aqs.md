# AQS

## AbstractQueuedSynchronizer

`java.util.concurrent.locks.AbstractQueuedSynchronizer`

1. `AbstractQueuedSynchronizer` 是一个模板抽象类,封装了算法细节,暴露了很多 `protected` 方法方便子类重写
2. `AbstractQueuedSynchronizer` 是基于 FIFO 队列实现的
3. `AbstractQueuedSynchronizer` 中使用 volatile int state 来`计数`
4. `AbstractQueuedSynchronizer` 可以实现可以重入锁(or 不可重入锁)的语义，如 ReentrantLock
5. `AbstractQueuedSynchronizer` 可以实现共享锁，排他锁的语义，如 ReentrantReadWriteLock
6. `AbstractQueuedSynchronizer` 可以实现公平锁，非公平锁的语义

## 参考

- [cas and aqs (csdn)](https://blog.csdn.net/u010862794/article/details/72892300)
- [aqs (github)](<https://github.com/CL0610/Java-concurrency/blob/master/08.%E5%88%9D%E8%AF%86Lock%E4%B8%8EAbstractQueuedSynchronizer(AQS)/%E5%88%9D%E8%AF%86Lock%E4%B8%8EAbstractQueuedSynchronizer(AQS).md>)
- [aqs (简书)](https://www.jianshu.com/p/cc308d82cc71)
- [aqs](https://wyj.shiwuliang.com/JAVA%20-%20AQS%E6%BA%90%E7%A0%81%E8%A7%A3%E8%AF%BB.html)
