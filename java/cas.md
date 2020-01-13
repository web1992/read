# CAS

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

## cas 优点缺点

- cas 使用循序，减少了CPU上下文的切换，但是它不会让出CPU资源，如果循环时间过长，独占CPU，CPU不能参与其他计算

## 实现

基于CPU的`cmpxchg`指令
