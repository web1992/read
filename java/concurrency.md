# concurrency

- [concurrency (from oracle for java8)](https://docs.oracle.com/javase/8/docs/technotes/guides/concurrency/index.html)
- [concurrency (from oracle)](https://docs.oracle.com/javase/tutorial/essential/concurrency/index.html)
- [concurrency (Overview)](https://docs.oracle.com/javase/8/docs/technotes/guides/concurrency/index.html)

## Increased reliability

Developing concurrent classes is difficult -- the low-level concurrency primitives provided by the Java language (synchronized, volatile, wait(), notify(), and notifyAll()) are difficult to use correctly, and errors using these facilities can be difficult to detect and debug. By using standardized, extensively tested concurrency building blocks, many potential sources of threading hazards such as deadlock, starvation, race conditions, or excessive context switching are eliminated. The concurrency utilities were carefully audited for deadlock, starvation, and race conditions.

## Task scheduling framework

- [Executor](executor.md)

## Fork/join framework

- [ForkJoinPool](fork-join-pool.md)

## Concurrent collections

- [BlockingQueue](blocking-queue.md)

## Atomic variables

- [atomic](atomic.md)

## Synchronizers

 General purpose synchronization classes, including `semaphores`, `barriers`, `latches`, `phasers`, and `exchangers`, **facilitate coordination between threads.**

- [CountDownLatch](count-down-latch.md)
- [CyclicBarrier](cyclic-barrier.md)

## Locks

- [ReentrantLock](reentrant-lock.md)
- [Condition](condition.md)

## Nanosecond-granularity timing