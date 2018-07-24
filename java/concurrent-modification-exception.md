# ConcurrentModificationException

`ConcurrentModificationException` 如果按照名字来翻译,应该是`并发修改异常`，比如我们常用的`ArrayList`是线成非安全的，如果存在多线程
修改`ArrayList`中的元素，那么在遍历集合时，会抛出异常，而不是一直的错下去，通常这个异常用来追踪Bug.（文章结尾有oracle的官方文档说明）

## 设计目的

This exception may be thrown by methods that have detected concurrent modification of an object when such modification is not permissible.

使用`fail-fast`在并发修改集合元素内容，如`add`,`remove`时，使集合可以自己检测到集合已经被修改了，后续的操作如果不中断，会产生其他问题，因此，抛出`ConcurrentModificationException`异常，中断流程。

## 什么时候产生

1.多线程并发修改集合元素时
2.单线程，在遍历元素的时候，删除元素，就会触发这个异常

如：

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

```out
1
Exception in thread "main" java.util.ConcurrentModificationException
	at java.util.ArrayList$Itr.checkForComodification(ArrayList.java:909)
	at java.util.ArrayList$Itr.next(ArrayList.java:859)
	at cn.web1992.utils.demo.collections.ArrayListTest.main(ArrayListTest.java:12)
```

我们知道Java中的`foreach`遍历，其实是Java的语法糖，其底层实现依然是`Iterator`(可使用javap -c 来查看)
而`Iterator`的实现都是对修改会做`fail-fast`处理的，`ArrayList`的`Iterator`实现是在`AbstractList`中的一个`Itr implements Iterator<E>`内部类



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