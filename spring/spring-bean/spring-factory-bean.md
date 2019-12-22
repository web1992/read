# FactoryBean

- [FactoryBean](#factorybean)
  - [Class Interface](#class-interface)
  - [Demo for FactoryBean](#demo-for-factorybean)
  - [Reference List](#reference-list)

## Class Interface

```java
public interface FactoryBean<T> {

    @Nullable
    T getObject() throws Exception;

    @Nullable
    Class<?> getObjectType();

    default boolean isSingleton() {
        return true;
    }
}
```

## Demo for FactoryBean

- SqlSessionFactoryBean
- MapperFactoryBean

## Reference List

- [https://www.cnblogs.com/aspirant/p/9082858.html](https://www.cnblogs.com/aspirant/p/9082858.html)
- [BeanFactory](spring-bean-factory.md)
