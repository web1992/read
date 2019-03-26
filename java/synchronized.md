# synchronized

## demo

```java
    public static void main(String[] args) throws InterruptedException {

        Object objectLock = new Object();


        Runnable r = () -> {
            try {
                TimeUnit.SECONDS.sleep(2);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            synchronized (objectLock) {
                System.out.println(getThreadName() + "notify...");
                objectLock.notify();
            }
        };

        new Thread(r).start();
        System.out.println(getThreadName() + "wait...");
        synchronized (objectLock) {
            objectLock.wait();
        }
        System.out.println(getThreadName() + "end...");
    }


    private static String getThreadName() {
        return "[" + Thread.currentThread().getName() + "] ";
    }
```
- [lock](lock.md)
