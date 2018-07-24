# ConcurrentModificationException

- [from cnblogs](http://www.cnblogs.com/dolphin0520/category/602384.html)
- [ConcurrentModificationException (from oracle)](https://docs.oracle.com/javase/8/docs/api/java/util/ConcurrentModificationException.html)

## 设计目的

This exception may be thrown by methods that have detected concurrent modification of an object when such modification is not permissible.

使用`fail-fast`在并发修改集合元素内容，如`add`,`remove`时，使集合可以自己检测到集合已经被修改了，后续的操作如果不中断，会产生其他问题，因此，抛出`ConcurrentModificationException`异常，中断流程。

## fail-fast

- [fail-fast (from wiki)](https://en.wikipedia.org/wiki/Fail-fast)
- [ArrayList.html#fail-fast](https://docs.oracle.com/javase/8/docs/api/java/util/ArrayList.html#fail-fast)

The iterators returned by this class's iterator and listIterator methods are fail-fast: if the list is structurally modified at any time after the iterator is created, in any way except through the iterator's own remove or add methods, the iterator will throw a ConcurrentModificationException. Thus, in the face of concurrent modification, the iterator fails quickly and cleanly, rather than risking arbitrary, non-deterministic behavior at an undetermined time in the future.


## Iterator

`Iterator`由来

- [Iterator (from wiki)](https://en.wikipedia.org/wiki/Iterator)