# thread

## start

## run

## interrupt

- [Interrupts](https://docs.oracle.com/javase/tutorial/essential/concurrency/interrupt.html)

我们知道启动一个线程是用`start()`方法，但是如何关闭（安全的）一个线程呢？

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
