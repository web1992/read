# MapperFactoryBean

- [MapperFactoryBean](#mapperfactorybean)
  - [MapperFactoryBean define](#mapperfactorybean-define)
  - [ClassPathMapperScanner.doScan](#classpathmapperscannerdoscan)
  - [MapperFactoryBean.checkDaoConfig](#mapperfactorybeancheckdaoconfig)
  - [MapperFactoryBean.getObject](#mapperfactorybeangetobject)
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

`MapperFactoryBean` 用来包装你写的 `Mapper` 类(接口)对象,在 `MapperScannerConfigurer` 中有如下的 `javadoc` 注释

```java
/**
 * BeanDefinitionRegistryPostProcessor that searches recursively starting from a base package for
 * interfaces and registers them as {@code MapperFactoryBean}. Note that only interfaces with at
 * least one method will be registered; concrete classes will be ignored.
*/
```

## ClassPathMapperScanner.doScan

负责扫描所有的 `Mapper` 并注册 `BeanDefinition`

在 `ClassPathMapperScanner.doScan` 方法中有下面的代码

```java
// the mapper interface is the original class of the bean
// but, the actual class of the bean is MapperFactoryBean
definition.getPropertyValues().add("mapperInterface", definition.getBeanClassName());
// 把 MapperFactoryBean 做为实际的 bean class
// 那么在spring 进行 bean 初始化的时候就会实例化 MapperFactoryBean 对象
// 有多少个mapper 对象，就有多少个 MapperFactoryBean 对象
// MapperFactoryBean 继承了 DaoSupport，bean 创建的时候，会执行 afterPropertiesSet
// 执行方法 afterPropertiesSet ->  checkDaoConfig
// 把 mapper 添加到 configuration 的 MapperRegistry 对象中
definition.setBeanClass(MapperFactoryBean.class);
```

## MapperFactoryBean.checkDaoConfig

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

## MapperFactoryBean.getObject

```java
  public T getObject() throws Exception {
    // 当其他对象依赖了 mapper
    // Spring 在进行依赖注入的时候，就会执行 getObject 返回 MapperProxy（getMapper返回的） 对象
    // 因为你只有接口，没有具体的实现类，MapperProxy 就是帮你生成的代理对象
    // 当你执行 mapper 的方法，其实是调用的 MapperProxy
    // 而最终 MapperProxy 会把请求给 sqlSession
    // 可以参考 MapperProxy.invoke 方法
    return getSqlSession().getMapper(this.mapperInterface);
  }
```

## RootBeanDefinition.beanClass
