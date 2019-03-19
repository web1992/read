# Condition

- [Condition (from oracle doc)](https://docs.oracle.com/javase/7/docs/api/java/util/concurrent/locks/Condition.html)

Condition factors out the Object monitor methods (wait, notify and notifyAll) into distinct objects to give the effect of having multiple wait-sets per object, by combining them with the use of arbitrary Lock implementations. Where a Lock replaces the use of synchronized methods and statements, a Condition replaces the use of the Object monitor methods.

`Condition` 类提供了类似 `Object` 类中的 `wait`, `notify` and `notifyAll` 方法，用来替换 `Object` 类，配合 `Lock` 类实现线程之间的通信[`synchronized`](synchronized.md)

## Condition interface

```java
public interface Condition {
    void await() throws InterruptedException;
    void awaitUninterruptibly();
    long awaitNanos(long nanosTimeout) throws InterruptedException;
    boolean await(long time, TimeUnit unit) throws InterruptedException;
    boolean awaitUntil(Date deadline) throws InterruptedException;
    void signal();
    void signalAll();
}
```

## await

`await` 会释放 `Condition` 对应 `lock` 的锁，让其他程序获取锁

Causes the current thread to wait until it is signalled or interrupted.
The lock associated with this Condition is atomically released and the current thread becomes disabled for thread scheduling purposes and lies dormant until one of four things happens:

- Some other thread invokes the signal() method for this Condition and the current thread happens to be chosen as the thread to be awakened; or
- Some other thread invokes the signalAll() method for this Condition; or
- Some other thread interrupts the current thread, and interruption of thread suspension is supported; or
- A "spurious wakeup" occurs.

## signal

## signalAll

## link

- [Condition](https://suichangkele.iteye.com/blog/2368254)