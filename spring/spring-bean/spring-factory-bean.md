# FactoryBean

- [FactoryBean](#factorybean)
  - [Class Interface](#class-interface)
  - [Demo for FactoryBean](#demo-for-factorybean)
  - [Reference List](#reference-list)

## Class Interface

> `FactoryBean` 用例创建 bean 对象，支持泛型

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

一些应用实例

- [SqlSessionFactoryBean](../java/../../java/mybatis/mybatis-sql-session-factory-bean.md)
- [MapperFactoryBean](../../java/mybatis/mybatis-mapper-factory-bean.md)
- org.apache.dubbo.config.spring.ServiceBean
- org.apache.dubbo.config.spring.ReferenceBean
- org.apache.dubbo.config.spring.ConfigCenterBean

## Reference List

- [https://www.cnblogs.com/aspirant/p/9082858.html](https://www.cnblogs.com/aspirant/p/9082858.html)
- [BeanFactory](spring-bean-factory.md)
