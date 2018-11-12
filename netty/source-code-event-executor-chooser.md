# EventExecutorChooser

`io.netty.util.concurrent.DefaultEventExecutorChooserFactory`

这个是 netty 中的一个线程轮询策略

代码：

```java
    public static void main(String[] args) {
        // 在8个线程中，轮询的选择一个
        // 从0 -> 7然后再从0 -> 7
        AtomicInteger idx = new AtomicInteger();
        int length = 8;
        for (int i = 0; i < 10; i++) {
            System.out.println("Math.abs="+Math.abs(idx.getAndIncrement() % length));
        }

        idx = new AtomicInteger();
        length = 8;

        for (int i = 0; i < 10; i++) {
            System.out.println("java &="+(idx.getAndIncrement() & length - 1));
        }
    }
```

结果:

```output
m1=0 m2=0
m1=1 m2=1
m1=2 m2=2
m1=3 m2=3
m1=4 m2=4
m1=5 m2=5
m1=6 m2=6
m1=7 m2=7
m1=0 m2=0
m1=1 m2=1
```
