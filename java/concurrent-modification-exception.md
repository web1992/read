# ConcurrentModificationException

`ConcurrentModificationException` 如果按照名字来翻译,应该是`并发修改异常`，比如我们常用的`ArrayList`是非线程安全的，如果存在多线程
修改`ArrayList`中的元素，那么在遍历集合时，会抛出异常，而不是一直的错下去，通常这个异常用来追踪Bug.（文章结尾有oracle的官方文档说明）

## 设计目的

This exception may be thrown by methods that have detected concurrent modification of an object when such modification is not permissible.

使用`fail-fast`在并发修改集合元素内容，如`add`,`remove`时，使集合可以自己检测到集合已经被修改了，后续的操作如果不中断，会产生其他问题，因此，抛出`ConcurrentModificationException`异常，中断流程。

## 设计原理

`AbstractList`中维护了 `expectedModCount` & `modCount`这个两个值，在新增，删除元素的时候，就会改变这个两个值，如果`Iterator`检测到了
`expectedModCount != modCount`,就会出现`ConcurrentModificationException`异常（也就是`fail-fast`处理）

## 什么时候产生

1. 多线程并发修改集合元素时
2. 单线程，在遍历元素的时候，删除元素，就会触发这个异常

### 单线程例子

```java
// jdk 1.8
public static void main(String[] args) {
        List<String> list=new ArrayList<>();
        list.add("1");
        list.add("2");
        list.add("3");
        for(String i:list){
            System.out.println(i);
            list.remove("3");
        }
    }
```

```log
1
Exception in thread "main" java.util.ConcurrentModificationException
    at java.util.ArrayList$Itr.checkForComodification(ArrayList.java:909)
    at java.util.ArrayList$Itr.next(ArrayList.java:859)
    at cn.web1992.utils.demo.collections.ArrayListTest.main(ArrayListTest.java:12)
```

我们知道Java中的`foreach`遍历，其实是Java的语法糖，其底层实现依然是`Iterator`(可使用javap -c 来查看)
而`Iterator`的实现都是对修改会做`fail-fast`处理的，`ArrayList`的`Iterator`实现是在`AbstractList`中的一个`Itr implements Iterator<E>`内部类

`list.remove("3")`这个方法其实是`List`自己实现的删除元素的方法，如果想在单线程中避免此异常可以使用`Iterator`接口中提供的`remove`方法

### 多线程例子

```java

       List<String> list = new ArrayList<>();

        list.add("1");
        list.add("2");
        list.add("3");
        list.add("4");
        list.add("6");

        Runnable r1 = () -> {
            Iterator<String> iterator = list.iterator();
            System.out.println("iterator start...");
            while (iterator.hasNext()) {
                String i = iterator.next();
                System.out.println(i);
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };
        // 添加一个元素
        Runnable r2 = () -> {
            list.add("666");
            System.out.println("add end...");
        };

        Thread t1 = new Thread(r1);
        Thread t2 = new Thread(r2);

        t1.start();
        t2.start();

```

日志：

```java
iterator start...
1
2
3
add end...
Exception in thread "Thread-0" java.util.ConcurrentModificationException
    at java.util.ArrayList$Itr.checkForComodification(ArrayList.java:909)
    at java.util.ArrayList$Itr.next(ArrayList.java:859)
    at cn.web1992.controller.ConcurrentModificationExceptionTest.lambda$main$0(ConcurrentModificationExceptionTest.java:37)
    at java.lang.Thread.run(Thread.java:748)
```

在多线程的环境下，`t2`线程如果在`t1`遍历的时候，向集合中添加了一个元素，那么就会出现`ConcurrentModificationException`异常

可使用Lock解决，代码如下：

```java
        // Lock
        ReentrantLock lock = new ReentrantLock();

        List<String> list = new ArrayList<>();

        list.add("1");
        list.add("2");
        list.add("3");
        list.add("4");
        list.add("6");

        Runnable r1 = () -> {
            try {
                // 获取锁
                lock.lock();
                Iterator<String> iterator = list.iterator();
                System.out.println("iterator start...");
                while (iterator.hasNext()) {
                    String i = iterator.next();
                    System.out.println(i);
                    try {
                        Thread.sleep(1000);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                // 释放锁
                lock.unlock();
            }
        };
        // 添加一个元素
        Runnable r2 = () -> {
            try {
                 // 获取锁
                lock.lock();
                list.add("666");
                System.out.println("add end...");
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                // 释放锁
                lock.unlock();
            }
        };

        Thread t1 = new Thread(r1);
        Thread t2 = new Thread(r2);

        t1.start();
        t2.start();

```

这里只是举一个例子，在实际应用中，如果同一时刻在只有一个线程可以访问这个`List`，效率通常十分低下，可以考虑使用java中的并发集合来解决这个问题，如[`CopyOnWriteArrayList`](copy-on-write.md)
`CopyOnWriteArrayList`适合`读多写少`的场景

## 思考

从`ConcurrentModificationException`可以获取到软件设计过程中，一些经典的设计思想（套路）如`Iterator`,`fail-fast`,这些思想在解决问题和分析定位问题的时候，了解其中的原理，帮助巨大，效率奇高。

## fail-fast

- [fail-fast (from wiki)](https://en.wikipedia.org/wiki/Fail-fast)
- [ArrayList.html#fail-fast](https://docs.oracle.com/javase/8/docs/api/java/util/ArrayList.html#fail-fast)

The iterators returned by this class's iterator and listIterator methods are fail-fast: if the list is structurally modified at any time after the iterator is created, in any way except through the iterator's own remove or add methods, the iterator will throw a ConcurrentModificationException. Thus, in the face of concurrent modification, the iterator fails quickly and cleanly, rather than risking arbitrary, non-deterministic behavior at an undetermined time in the future.

## Iterator

`Iterator`由来

- [Iterator (from wiki)](https://en.wikipedia.org/wiki/Iterator)

## 好文链接

- [from cnblogs](http://www.cnblogs.com/dolphin0520/category/602384.html)
- [ConcurrentModificationException (from oracle)](https://docs.oracle.com/javase/8/docs/api/java/util/ConcurrentModificationException.html)