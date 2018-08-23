# Queue

- [Queue (from oracle docs)](https://docs.oracle.com/javase/tutorial/collections/implementations/queue.html)

![Queue](images/queue.png)

## BlockingQueue Method

||Throws exception|Special value|Blocks|Times out
------|----------|-------------|------|----------
Insert|add(e)|offer(e)|put(e)|offer(e, time, unit)
Remove|remove()|poll()|take()|poll(time, unit)
Examine(检查)|element()|peek()|not applicable|not applicable

## ArrayBlockingQueue

![ArrayBlockingQueue](./images/ArrayBlockingQueue.png)

- FIFO (first-in-first-out)先进先出
- 底层实现是数组
- 添加元素总是在队列末部
- 删除元素总是在队列头部
- 基于数组,大小在初始化时固定不变
- 如果queue满了，`put`方法继续添加元素的时候，就会阻塞
- 如果quue是空的，`take`方法会阻塞一直到有数据插入

put 方法

```java
    public void put(E e) throws InterruptedException {
        checkNotNull(e);
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        try {
            while (count == items.length)
                notFull.await();
            enqueue(e);
        } finally {
            lock.unlock();
        }
    }
```

take 方法

```java
    public E take() throws InterruptedException {
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        try {
            while (count == 0)
                notEmpty.await();
            return dequeue();
        } finally {
            lock.unlock();
        }
    }
```