# ReentrantLock

- [@see Condition](condition.md)

- [ReentrantLock](#reentrantlock)
  - [特点](#%E7%89%B9%E7%82%B9)
  - [demo](#demo)
  - [Link](#link)

## 特点

可重入的锁

- 可以重入，同一个线程可以多次获取锁
- 可以实现`公平锁`&`非公平锁`
- 必须使用 `try` `finally`来释放锁
- 可以使用`tryLock`设置锁的超时时间

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

- [java lock](https://tech.meituan.com/2018/11/15/java-lock.html)
