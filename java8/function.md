# Function

```java
List<Vo> collect = list.stream().map(item -> this.copy(item, Vo::new)).collect(Collectors.toList());

private Vo domainToVo(Domain config) {
    Vo vo = new Vo();
    BeanUtils.copyProperties(config, vo);
    return vo;
}
private Domain voToDomain(Vo vo) {
    Domain domain = new Domain();
    BeanUtils.copyProperties(vo, domain);
    return domain;
}
```

> 使用 Function 进行重构

```java
private <T, R> R copy(T sourceObject, Supplier<R> targetObject) {
    R r = targetObject.get();
    // 执行 copy
    Function<T, R> f = source -> {
        BeanUtils.copyProperties(source, r);
        return r;
    };
    return f.apply(sourceObject);
}
```
