# CountDownLatch

- [CountDownLatch](#countdownlatch)
  - [docs](#docs)
  - [example1](#example1)
  - [example2](#example2)
  - [example3](#example3)

`CountDownLatch` 可以用来处理几个线程之间的协作，如 A 线程等待 B,C,D 线程任务完成之后，再执行 A 自己的任务。

- [CountDownLatch](https://www.cnblogs.com/shiyanch/archive/2011/04/04/2005233.html)
- [CountDownLatch from oracle docs](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CountDownLatch.html)

## docs

A synchronization aid that allows one or more threads to wait until
a set of operations being performed in other threads completes.

## example1

The first is a start signal that prevents any worker from proceeding
until the driver is ready for them to proceed;
The second is a completion signal that allows the driver to wait
until all workers have completed.

```java
class Driver {
  void main() throws InterruptedException {
    // startSignal 开始的信号
    CountDownLatch startSignal = new CountDownLatch(1);
    //  完成的信号
    CountDownLatch doneSignal = new CountDownLatch(N);
     for (int i = 0; i < N; ++i) // create and start threads
      new Thread(new Worker(startSignal, doneSignal)).start();
     doSomethingElse();            // don't let run yet
    // 发出开始的信号
    startSignal.countDown();      // let all threads proceed
    doSomethingElse();
    // 完成的信号进行等待（等待所有线程完成任务）
    doneSignal.await();           // wait for all to finish
  }
}
 class Worker implements Runnable {
  private final CountDownLatch startSignal;
  private final CountDownLatch doneSignal;
  Worker(CountDownLatch startSignal, CountDownLatch doneSignal) {
    this.startSignal = startSignal;
    this.doneSignal = doneSignal;
  }
  public void run() {
    try {
      // 这里是异步的，每个线程都等待 开始的信号
      startSignal.await();
      doWork();
      // 每个线程执行之后，通知说：我完成了任务
      doneSignal.countDown();
    } catch (InterruptedException ex) {} // return;
  }
   void doWork() {
       // ...
    }
}
```

## example2

Another typical usage would be to divide a problem into N parts,
describe each part with a Runnable that executes that portion and
counts down on the latch, and queue all the `Runnables` to an
Executor. When all sub-parts are complete, the coordinating thread
will be able to pass through await. (When threads must repeatedly
count down in this way, instead use a {@link `CyclicBarrier`}.)

```java
class Driver2 {
   void main() throws InterruptedException {
     CountDownLatch doneSignal = new CountDownLatch(N);
     Executor e = //...
     for (int i = 0; i < N; ++i) // create and start threads
       e.execute(new WorkerRunnable(doneSignal, i));
     // 在其它线程完成任务之前，主线程一直阻塞
     doneSignal.await();           // wait for all to finish
   }
 }
 class WorkerRunnable implements Runnable {
   private final CountDownLatch doneSignal;
   private final int i;
   WorkerRunnable(CountDownLatch doneSignal, int i) {
     this.doneSignal = doneSignal;
     this.i = i;
   }
   public void run() {
     try {
       doWork(i);
       doneSignal.countDown();
     } catch (InterruptedException ex) {} // return;
   }
   void doWork() { /* ...*/ }
 }
```

[Thread#join()](thread.md#join)A 程等待 B 线程执行完毕之后，A 线程继续执行，实现了二个线程协作的机制

`CountDownLatch`A 线程等待 B,C,D,E 线程等完成之后，A 线程继续执行，实现了 N 个线程之间的协作机制

## example3

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
