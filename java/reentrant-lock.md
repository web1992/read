# ReentrantLock

- [@see Condition](condition.md)

## 特点

可重入的锁

- 可以重入，同一个线程可以多次获取锁
- 可以实现`公平锁`&`非公平锁`
- 必须使用 `try` `finally`来释放锁
- 可以使用`tryLock`设置锁的超时时间