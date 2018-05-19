# optional

## methond list

常用的方法

```java
    empty
    of
    ofNullable
    ifPresent
    filter
    map
    flatMap
    orElse
    orElseGet
    EMPTY
```

不建议使用的方法

```java
    get // 会出现`NoSuchElementException` 异常
    isPresent // 作用和  if(obj !=null){doSomething()} 一样
```