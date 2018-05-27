# optional

## method list

### 常用的方法

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

### 不建议使用的方法

```java
    get // 会出现`NoSuchElementException` 异常
    isPresent // 作用和  if(obj !=null){doSomething()} 一样
```

### 使用 optional 代替空判断

```java
    public String getCarInsuranceName(Person person){
        return Optional
                .ofNullable(person)
                .flatMap(Person::getCar)
                .flatMap(Car::getInsurance)
                .flatMap(Insurance::getName)
                .orElse("Unknown");
    }
```

### Optional 字段无法序列化

**没有实现`Serializable`接口**

> 设计的目的是为了可以返回 `Optional<Object>` 对象的语法

```java
    public class Person{
        private Car car;
        // 表示Car字段可能是空的
        // Optional 提供了新的语义
        public Optional<Car> getCar(){
            return Optional.ofNullable(car);
        }
    }
```
