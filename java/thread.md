# thread

- [thread](#thread)
  - [ThreadFactory](#threadfactory)
  - [ThreadGroup](#threadgroup)
  - [start](#start)
  - [run](#run)
  - [interrupt](#interrupt)
  - [join](#join)
  - [yield](#yield)
  - [sleep](#sleep)
  - [InterruptedException](#interruptedexception)
  - [stop](#stop)

## ThreadFactory

可以方便的定义thread name，daemon status，priority, thread Group

一个默认的实现`java.util.concurrent.Executors.DefaultThreadFactory`

## ThreadGroup

## start

```java
        Thread t = new Thread(() -> System.out.println(Thread.currentThread().getName()+" start ..."));
        t.start();// 启动线程
```

`start` 会调用一个`start0`方法，让jvm启用一个线程

Causes this thread to begin execution; the Java Virtual Machine
calls the `run` method of this thread.

## run

```java
    @Override
    public void run() {
        if (target != null) {
            target.run();
        }
    }
```

## interrupt

- [Interrupts](https://docs.oracle.com/javase/tutorial/essential/concurrency/interrupt.html)
- [Thread stop](http://www.java67.com/2015/07/how-to-stop-thread-in-java-example.html)

我们知道启动一个线程是用`start()`方法，但是如何关闭（安全的）一个线程呢？

使用`volatile`标记+`interrupt`

- volatile变量,如果线程检查到的状态是关闭的，那么次变量不接受新的任务即可
- volatile变量,保证可见性（一个线程修改变量的结果，对其他线程可见）
- interrupt 使阻塞（blocked）状态的线程，出现`InterruptedException`异常，进行终止

## join

> Waits for this thread to die.

- 一个线程等待另一个线程完成后，该线程继续执行
- join 实现的是`wait()`+`notifyAll`(`notify`)

```java
    public static void main(String[] args) throws Exception {
        Runnable r = () -> {
            System.out.println("run ...");
            try {
                Thread.sleep(3 * 1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println("run end ...");
        };
        Thread thread1 = new Thread(r);

        Runnable r2 = () -> {

            try {
                System.out.println("run2 ...");
                thread1.join();
                System.out.println("run2 end ...");
            } catch (Exception e) {
                e.printStackTrace();
            }
        };

        Thread thread2 = new Thread(r2);

        thread1.start();
        thread2.start();
    }
```

```log
        // t2 在t1之前结束
        // run ...
        // run2 ...
        // run2 end ...
        // run end ...

        // use thread1.join();
        // t2必在t1完成后结束(t2一直等待t1结束)
        // run ...
        // run2 ...
        // run end ...
        // run2 end ...
```

## yield

- [thread yield](https://www.javamex.com/tutorials/threads/yield.shtml)

线程让出cpu（别用）

## sleep

```java
    // use TimeUnit
    TimeUnit.MILLISECONDS.sleep(200);
    // user Thread
    Thread..sleep(200);
```

## InterruptedException

`InterruptedException` 是如何产生的demo

```java
    public static void main(String[] args) throws InterruptedException {

        Runnable r = () -> {
            try {
                System.out.println("[I am " + Thread.currentThread().getName() + "] thread");
                Thread.sleep(2 * 1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        };

        Thread t = new Thread(r);
        t.start();
        // throw InterruptedException
        System.out.println("[I am " + Thread.currentThread().getName() + "] thread");
        t.interrupt();
    }
```

日志

```txt
[I am main] thread
[I am Thread-0] thread
java.lang.InterruptedException: sleep interrupted
    at java.lang.Thread.sleep(Native Method)
    at com.aldb.payment.remit.T.lambda$main$0(T.java:24)
    at java.lang.Thread.run(Thread.java:748)
```

- 1.如果一个线程在`sleep`状态（wait,join,sleep），调用interrupt 会出现`InterruptedException`异常

## stop

- [threads](http://winterbe.com/posts/2015/04/07/java8-concurrency-tutorial-thread-executor-examples/)
- [stop thread](http://forward.com.au/javaProgramming/HowToStopAThread.html)