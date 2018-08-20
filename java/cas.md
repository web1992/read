# CAS

- [cas(from iteye)](http://zl198751.iteye.com/blog/1848575)
- [cas(form ifeve)](http://ifeve.com/atomic-operation/)

## Unsafe

java 中的`cas`操作的都是基于`Unsafe`实现的，`Unsafe`使用`JNI`调用`C++`方法，提现平台相关的实现

## Unsafe demo

```java
    // 获取一个 Unsafe实例
    Field field = Unsafe.class.getDeclaredField("theUnsafe");
    field.setAccessible(true);
     Unsafe unsafe = (Unsafe) field.get(null);
     System.out.println(unsafe);
```
