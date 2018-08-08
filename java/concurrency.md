# concurrency

- [concurrency (from oracle for java8)](https://docs.oracle.com/javase/8/docs/technotes/guides/concurrency/index.html)
- [concurrency (from oracle)](https://docs.oracle.com/javase/tutorial/essential/concurrency/index.html)
- [concurrency (Overview)](https://docs.oracle.com/javase/8/docs/technotes/guides/concurrency/index.html)

## CountDownLatch

- [CountDownLatch](https://www.cnblogs.com/shiyanch/archive/2011/04/04/2005233.html)
- [CountDownLatch](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CountDownLatch.html)

demo 

```java
/**
     *  模拟一个开会的场景，10人到齐了，会议开始
     *
     * @param args
     * @throws InterruptedException
     */
    public static void main(String[] args) throws InterruptedException {

        // 10人
        int meeters = 10;
        CountDownLatch enter = new CountDownLatch(1);
        CountDownLatch arrive = new CountDownLatch(meeters);


        for (int i = 0; i < meeters; i++) {
            new Thread(() -> {
                try {
                    enter.await();
                    doWork();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    arrive.countDown();

                }

            }).start();
        }

        // 开始入场
        enter.countDown();
        // 等待人到齐
        arrive.await();
        // 人到齐了，开始开会
        System.out.println("meet begin...");
    }

    private static void doWork() {
        String name = Thread.currentThread().getName();
        System.out.println(name + " arrive ...");
    }
```

## Increased reliability

Developing concurrent classes is difficult -- the low-level concurrency primitives provided by the Java language (synchronized, volatile, wait(), notify(), and notifyAll()) are difficult to use correctly, and errors using these facilities can be difficult to detect and debug. By using standardized, extensively tested concurrency building blocks, many potential sources of threading hazards such as deadlock, starvation, race conditions, or excessive context switching are eliminated. The concurrency utilities were carefully audited for deadlock, starvation, and race conditions.

## Task scheduling framework

## Fork/join framework

## Concurrent collections

## Atomic variables

## Synchronizers

## Locks

## Nanosecond-granularity timing