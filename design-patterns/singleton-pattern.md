# Singleton pattern

- [Singleton pattern](https://en.wikipedia.org/wiki/Singleton_pattern)

## Implementation

An implementation of the singleton pattern must:

- ensure that only one instance of the singleton class ever exists; and
- provide global access to that instance.

Typically, this is done by:

- declaring all constructors of the class to be private; and
- providing a static method that returns a reference to the instance.

The instance is usually stored as a `private static` variable; the instance is created when the variable is initialized, at some point before the static method is first called. The following is a sample implementation written in Java.

```java
public final class Singleton {

    private static final Singleton INSTANCE = new Singleton();

    private Singleton() {}

    public static Singleton getInstance() {
        return INSTANCE;
    }
}
```

## Lazy initialization

因为是静态的，多线程访问的时候，并发存在问题，因此需要加锁

```java
public final class Singleton {

    private static volatile Singleton instance = null;

    private Singleton() {}

    public static Singleton getInstance() {
        if (instance == null) {
            synchronized(Singleton.class) {
                if (instance == null) {
                    instance = new Singleton();
                }
            }
        }

        return instance;
    }
}
```

使用静态内部类，实现`懒加载`

```java
public class Something {
    private Something() {}

    private static class LazyHolder {
        static final Something INSTANCE = new Something();
    }

    public static Something getInstance() {
        return LazyHolder.INSTANCE;
    }
}
```

实现原理：

上面的代码片段,`LazyHolder` 是一个静态内部类，只有在`getInstance`第一次被调用的时候，才会执行类加载，而 JVM，JLS（Java Language Specification） 保证了类加载的安全性

Since the class does not have any static variables to initialize, the initialization completes trivially.

❌ The idiom can only be used when the construction of Something can be guaranteed to not fail. In most JVM implementations, if construction of Something fails, subsequent attempts to initialize it from the same class-loader will result in a `NoClassDefFoundError` failure.

注意：使用这种方式，必须保证构造方法成功的只想，不然会出现 `NoClassDefFoundError`错误

## 好文链接

- [Double-checked_locking](https://en.wikipedia.org/wiki/Double-checked_locking)
