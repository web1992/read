# atomic

`java.util.concurrent.atomic`

- AtomicBoolean
- AtomicInteger
- AtomicIntegerArray
- AtomicIntegerFieldUpdater
- AtomicLong
- AtomicLongArray
- AtomicLongFieldUpdater
- AtomicMarkableReference
- AtomicReference
- AtomicReferenceArray
- AtomicReferenceFieldUpdater
- AtomicStampedReference
- DoubleAccumulator
- DoubleAdder
- LongAccumulator
- LongAdder
- Striped64

## 实现

`volatile`关键字+`sun.misc.Unsafe`类

- 使用`volatile`关键字，保证A线程修改值的时候，对B线程可见
- 使用`sun.misc.Unsafe`的`CAS`方法，实现值的更新

## demo

自己实现一个`AtomicInteger`

```java
    private static final Integer MAX = 50000;

    public static void main(String[] args) throws InterruptedException {

        CountDownLatch countDownLatch = new CountDownLatch(MAX);
        AtomicInt atomicInt = new AtomicInt();
        for (int i = 0; i < MAX; i++) {
            new Thread(() -> {
                atomicInt.getAndInr();
                countDownLatch.countDown();
            }).start();
        }
        // 等待其他线程完成
        countDownLatch.await();
        System.out.println(atomicInt.get());
    }


    static class AtomicInt {
        // 这种方法受限
        // private static final Unsafe unsafe = Unsafe.getUnsafe();
        private static Unsafe unsafe = null;

        private static final long valueOffset;

        static {
            try {
                Field field = Unsafe.class.getDeclaredField("theUnsafe");
                field.setAccessible(true);
                unsafe = (Unsafe) field.get(null);
                valueOffset = unsafe.objectFieldOffset(AtomicInt.class.getDeclaredField("value"));
            } catch (Exception ex) {
                throw new Error(ex);
            }
        }

        private volatile int value;


        public AtomicInt(int value) {
            this.value = value;
        }

        public AtomicInt() {
        }

        public Integer get() {
            return value;
        }

        /**
         * 核心代码cas
         *
         * @return
         */
        public Integer getAndInr() {
            while (true) {
                // 当前的值
                int curValue = this.value;// value 是volatile，因此这个值的修改是线程间可见的
                // 新值
                int newValue = curValue + 1;
                // 如果 curValue = newValue  当前的值没有被其他线程修改，compareAndSwapInt更新成功
                // 如果 curValue != newValue 当前的值已经被其他线程修改,重新获取curValue，然后再次执行compareAndSwapInt
                if (unsafe.compareAndSwapInt(this, valueOffset, curValue, newValue)) {
                    return newValue;
                }
            }
        }
    }
```