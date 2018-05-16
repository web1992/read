# stream

## 特点

- 声明式 更简洁，更易读
- 可复合 更灵活
- 可并行 性能更好
- 只能便利一次

## 流的方法

### filter

```java
    List<String> list=Arrays.asList("java","stream","filter")
    list.stream()
        .filter(str.length()>4)
        .collect(toList());
```

### distinct


### limit


### skip


### map


### flatMap


### sorted


### anyMatch


### noneMatch


### allMatch


### findAny


### findFirst


### forEach


### collect


### reduce

### count