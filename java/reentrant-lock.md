# ReentrantLock

- [@see Condition](condition.md)

- [ReentrantLock](#reentrantlock)
  - [特点](#%E7%89%B9%E7%82%B9)
  - [可重入的实现](#%E5%8F%AF%E9%87%8D%E5%85%A5%E7%9A%84%E5%AE%9E%E7%8E%B0)
  - [公平锁&非公平锁的实现](#%E5%85%AC%E5%B9%B3%E9%94%81%E9%9D%9E%E5%85%AC%E5%B9%B3%E9%94%81%E7%9A%84%E5%AE%9E%E7%8E%B0)
    - [NonfairSync](#nonfairsync)
    - [FairSync](#fairsync)
  - [demo](#demo)
  - [Link](#link)

## 特点

- 提供了和 `synchronized` 同样的语义，但是扩展了 `synchronized`
- 可以重入，同一个线程可以多次获取锁
- 可以实现 `公平锁` & `非公平锁`
- 必须使用 `try` `finally` 来释放锁
- 可以使用 `tryLock` 设置锁的超时时间

## 可重入的实现

> 陷阱： 如果使用了两次 try 获取锁，那么必须使用两次 unlock 去释放锁，否则其他线程会获取不到锁

## 公平锁&非公平锁的实现

`ReentrantLock` 使用两个内部类 `NonfairSync` 和 `FairSync` 来实现非公平锁和公平锁

### NonfairSync

```java
static final class NonfairSync extends Sync {
    private static final long serialVersionUID = 7316153563782823691L;
    /**
     * Performs lock.  Try immediate barge, backing up to normal
     * acquire on failure.
     */
    final void lock() {
        // 非公平锁在获取锁的时候，直接尝试修改 AbstractQueuedSynchronizer 的 state 字段来获取锁
        // 如果修改成功，那么就获取锁成功
        if (compareAndSetState(0, 1))
            setExclusiveOwnerThread(Thread.currentThread());
        else
            acquire(1);// 尝试获取锁失败，就去获取锁
    }
    protected final boolean tryAcquire(int acquires) {
        return nonfairTryAcquire(acquires); // 执行 nonfairTryAcquire 方法获取锁
    }
}

// Sync#nonfairTryAcquire
// nonfairTryAcquire 与 FairSync 的 tryAcquire 少了一个 !hasQueuedPredecessors() 这个操作
// hasQueuedPredecessors 方法会检查是否有线程在队列中，如果没有才会尝试获取锁
final boolean nonfairTryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    if (c == 0) {
        if (compareAndSetState(0, acquires)) {
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {
        int nextc = c + acquires;
        if (nextc < 0) // overflow
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}
```

### FairSync

```java
    static final class FairSync extends Sync {
        private static final long serialVersionUID = -3000897897090466540L;

        final void lock() {
            acquire(1);// 这里和 NonfairSync 的 lock  方法对比,少了一次尝试的动作
        }

        /**
         * Fair version of tryAcquire.  Don't grant access unless
         * recursive call or no waiters or is first.
         */
        protected final boolean tryAcquire(int acquires) {
            final Thread current = Thread.currentThread();
            int c = getState();
            if (c == 0) {
                if (!hasQueuedPredecessors() &&// 没有排队的线程才尝试获取锁，否则获取锁失败
                    compareAndSetState(0, acquires)) {
                    setExclusiveOwnerThread(current);
                    return true;
                }
            }
            else if (current == getExclusiveOwnerThread()) {
                int nextc = c + acquires;
                if (nextc < 0)
                    throw new Error("Maximum lock count exceeded");
                setState(nextc);
                return true;
            }
            return false;
        }
    }
```

## demo

```java
// 一个阻塞队列实现
class BlockArray<E> {

    Object[] element;


    int size;
    int count;
    int putprt;
    int takeptr;

    public BlockArray(int size) {
        this.size = size;
        element = new Object[size];
    }


    final ReentrantLock lock = new ReentrantLock();

    final Condition empty = lock.newCondition();

    final Condition full = lock.newCondition();


    public E put(E e) throws InterruptedException {
        lock.lock();
        try {
            while (count == size) {
                full.await();
            }
            element[putprt++] = e;
            if (putprt == size) {
                putprt = 0;
            }
            ++count;
            empty.signal();
        } finally {
            lock.unlock();
        }

        return e;
    }

    public E take() throws InterruptedException {
        E e = null;
        lock.lock();
        try {
            while (count == 0) {
                empty.await();
            }
            e = (E) element[takeptr++];
            if (takeptr == size) {
                takeptr = 0;
            }
            --count;
            full.signal();
        } finally {
            lock.unlock();
        }
        return e;
    }

}
    // test
    public static void main(String[] args) {
        BlockArray<Integer> blockArray = new BlockArray(5);

        new Thread(() -> {
            try {
                while (true) {
                    System.out.println("get " + blockArray.take());
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();

        IntStream.range(0, 10).forEach(i -> {
            try {
                blockArray.put(i);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });
    }

```

## Link

- [https://tech.meituan.com/2018/11/15/java-lock.html](https://tech.meituan.com/2018/11/15/java-lock.html)
