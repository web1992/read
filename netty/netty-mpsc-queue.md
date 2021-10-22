# MpscQueue

多生产者，单消费者 Queue mpsc (multi-producer single consumer queue)

## 在 HashedWheelTimer 中的应用

```java
// HashedWheelTimer
private final Queue<HashedWheelTimeout> timeouts = PlatformDependent.newMpscQueue();
```