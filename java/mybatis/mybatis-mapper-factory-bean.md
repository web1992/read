# MapperFactoryBean

- [MapperFactoryBean](#mapperfactorybean)
  - [MapperFactoryBean define](#mapperfactorybean-define)
  - [MapperFactoryBean.getObject](#mapperfactorybeangetobject)
  - [checkDaoConfig](#checkdaoconfig)
  - [RootBeanDefinition.beanClass](#rootbeandefinitionbeanclass)

## MapperFactoryBean define

```java
/**
 * BeanFactory that enables injection of MyBatis mapper interfaces. It can be set up with a
 * SqlSessionFactory or a pre-configured SqlSessionTemplate.
 **/
public class MapperFactoryBean<T> extends SqlSessionDaoSupport implements FactoryBean<T> {

}
```

用来获取你写的 `Mapper` 类对象

## MapperFactoryBean.getObject

```java
  public T getObject() throws Exception {
    return getSqlSession().getMapper(this.mapperInterface);
  }
```

## checkDaoConfig

```java
  protected void checkDaoConfig() {
    super.checkDaoConfig();

    notNull(this.mapperInterface, "Property 'mapperInterface' is required");

    Configuration configuration = getSqlSession().getConfiguration();
    if (this.addToConfig && !configuration.hasMapper(this.mapperInterface)) {
      try {
        configuration.addMapper(this.mapperInterface);
      } catch (Throwable t) {
        logger.error("Error while adding the mapper '" + this.mapperInterface + "' to configuration.", t);
        throw new IllegalArgumentException(t);
      } finally {
        ErrorContext.instance().reset();
      }
    }
  }
```

## RootBeanDefinition.beanClass
