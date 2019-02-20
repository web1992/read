# CyclicBarrier

字面意思：循环的栏栅

## docs

A synchronization aid that allows a set of threads to all wait for
each other to reach a common barrier point. `CyclicBarriers` are
useful in programs involving a fixed sized party of threads that
must occasionally wait for each other. The barrier is called
`cyclic` because it can be re-used after the waiting threads
are released.

## demo

```java
public class CyclicBarrierDemo {
    public static void main(String[] args) {

        CyclicBarrier cyclicBarrier = new CyclicBarrier(5, () -> System.out.println("done ..."));

        IntStream.range(0, 5).forEach(i -> new Thread(() -> {
            try {
                cyclicBarrier.await(1, TimeUnit.SECONDS);
                System.out.println("await done ..." + i);
            } catch (InterruptedException | BrokenBarrierException | TimeoutException e) {
                e.printStackTrace();
            }
        }).start());

    }
}
```