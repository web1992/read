# ThreadLocal

- [ThreadLocal](#threadlocal)
  - [Example](#example)
  - [initialValue](#initialvalue)
  - [set](#set)
  - [get](#get)
  - [ThreadLocal-gc](#threadlocal-gc)
  - [ThreadLocalMap](#threadlocalmap)
    - [ThreadLocalMap key](#threadlocalmap-key)
    - [ThreadLocalMap value](#threadlocalmap-value)
  - [io.netty.util.concurrent.FastThreadLocal](#ionettyutilconcurrentfastthreadlocal)
  - [参考资料](#%E5%8F%82%E8%80%83%E8%B5%84%E6%96%99)

## Example

```java
// ThreadLocal 使用静态变量
private final static ThreadLocal<String> THREAD_LOCAL = new ThreadLocal<String>() {
    @Override
    protected String initialValue() {
        // 因为有两个线程使用了 THREAD_LOCAL
        // initialValue 方法会执行两次
        String name = Thread.currentThread().getName();
        System.out.println("ThreadLocal init " + name);
        System.out.println(this);
        return "ThreadLocal " + name;
    }
};
public static void main(String[] args) {
    System.out.println(THREAD_LOCAL.get());
    // 新线程
    new Thread(() -> {
        System.out.println("thread " + THREAD_LOCAL.get());
        THREAD_LOCAL.set("new value");
        System.out.println("thread after set " + THREAD_LOCAL.get());
    }).start();
    try {
        TimeUnit.SECONDS.sleep(1L);
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
    // 主线程
    System.out.println("main " + THREAD_LOCAL.get());
}
```

## initialValue

```java
// 用来赋值一个初始化的值
protected T initialValue() {
    return null;
}
```

## set

```java
// 设置一个新的值
// set 方法会查询 Thread 的局部变量字段 ThreadLocalMap 是否有值
// 不为空，设置值
// 为空，进行 ThreadLocalMap 的初始化
public void set(T value) {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
}

ThreadLocalMap getMap(Thread t) {
    return t.threadLocals;
}

// new 一个 ThreadLocalMap
// 赋值给 Thread 的局部变量
// 这里的 this 其实是 ThreadLocal 实例
void createMap(Thread t, T firstValue) {
    t.threadLocals = new ThreadLocalMap(this, firstValue);
}

// ThreadLocalMap 这个方法也很重要
// 会通过 ThreadLocal 计算出 hashcode
// 使用 Entry 包装 key,value
// 放在 Entry[] 数组中
// 因为使用 hashcode 计算索引
// 因此数据在 Entry[] 数组中 并不一定是连续的
// 同时也会产生hash 冲突，产生冲突之后就会形成链表
ThreadLocalMap(ThreadLocal<?> firstKey, Object firstValue) {
    table = new Entry[INITIAL_CAPACITY];
    int i = firstKey.threadLocalHashCode & (INITIAL_CAPACITY - 1);
    table[i] = new Entry(firstKey, firstValue);
    size = 1;
    setThreshold(INITIAL_CAPACITY);
}
```

## get

```java
// 先检查 ThreadLocalMap 是否为空
// 为空则进行初始化
public T get() {
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null) {
        ThreadLocalMap.Entry e = map.getEntry(this);
        if (e != null) {
            @SuppressWarnings("unchecked")
            T result = (T)e.value;
            return result;
        }
    }
    return setInitialValue();
}
// 初始化
// 调用 initialValue 获取自定义的初始化的值
// 检查map
// 为空则进行初始化
private T setInitialValue() {
    T value = initialValue();
    Thread t = Thread.currentThread();
    ThreadLocalMap map = getMap(t);
    if (map != null)
        map.set(this, value);
    else
        createMap(t, value);
    return value;
}
```

## ThreadLocal-gc

## ThreadLocalMap

`ThreadLocalMap` 是 `ThreadLocal` 的内部类, `ThreadLocalMap` 使用 `hash` 算法,存储数据

一个业务对应一个`ThreadLocal` 如：一个存储用户信息，另一个存在数据库连接

> 伪代码

```java
// 用户信息
private final static ThreadLocal<User> THREAD_LOCAL_FOR_USER = new ThreadLocal<User>() {
    @Override
    protected User initialValue() {
      return null;
    }
};

// 数据库连接
private final static ThreadLocal<Connection> THREAD_LOCAL_FOR_CONNECTION= new ThreadLocal<Connection>() {
    @Override
    protected Connection initialValue() {
       return null;
    }
};
```

而 `ThreadLocalMap` 每个线程 `Thread` 都会维护自己的 `map`

当进行数据存储的时候，会把数据存在 `ThreadLocalMap` 中，这样就可以实现 `线程本地变量`。

### ThreadLocalMap key

ThreadLocalMap 的 key 是 ThreadLocal 的实例

### ThreadLocalMap value

ThreadLocalMap 的 value 是要存在的信息如，用户信息，数据库连接

## io.netty.util.concurrent.FastThreadLocal

不得不说的  `io.netty.util.concurrent.FastThreadLocal` Netty 中对 `java.lang.ThreadLocal` 的优化

- [source-code-fast-thread-local.md](../netty/source-code-fast-thread-local.md)

## 参考资料

- [ThreadLocl (简书)](https://www.jianshu.com/p/dde92ec37bd1)
- [threadLocal 内存泄漏的原因](https://stackoverflow.com/questions/17968803/threadlocal-memory-leak)
- [threadLocal 优化](https://www.cnblogs.com/zhjh256/p/6367928.html)
- [ThreadLocl (github)](https://github.com/CL0610/Java-concurrency/blob/master/17.%E5%B9%B6%E5%8F%91%E5%AE%B9%E5%99%A8%E4%B9%8BThreadLocal/%E5%B9%B6%E5%8F%91%E5%AE%B9%E5%99%A8%E4%B9%8BThreadLocal.md)
