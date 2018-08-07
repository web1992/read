# thread

## start

## run

## interrupt

- [Interrupts](https://docs.oracle.com/javase/tutorial/essential/concurrency/interrupt.html)
- [Thread stop](http://www.java67.com/2015/07/how-to-stop-thread-in-java-example.html)

我们知道启动一个线程是用`start()`方法，但是如何关闭（安全的）一个线程呢？

使用`volatile`标记+`interrupt`

- volatile变量，如果线程检查到的状态是关闭的，那么次变量不接受新的任务即可
- interrupt 使阻塞（blocked）状态的线程，出现`InterruptedException`异常，进行终止

## join

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
