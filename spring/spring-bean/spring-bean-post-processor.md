# BeanPostProcessor

与 [BeanFactoryPostProcessor](./spring-bean-factory-post-processor.md) 类似

`AutowiredAnnotationBeanPostProcessor` 是 `InstantiationAwareBeanPostProcessor` 的实现类之一，也是 `@Autowired` 依赖注入的具体实现

`InstantiationAwareBeanPostProcessor` 实现了 `BeanPostProcessor` 接口,这里二个类放在一起进行学习。

- [BeanPostProcessor](#beanpostprocessor)
  - [Where load BeanPostProcessor](#where-load-beanpostprocessor)
  - [The hook method in BeanPostProcessor](#the-hook-method-in-beanpostprocessor)
  - [The load method PostProcessorRegistrationDelegate](#the-load-method-postprocessorregistrationdelegate)
    - [PostProcessorRegistrationDelegate.registerBeanPostProcessors](#postprocessorregistrationdelegateregisterbeanpostprocessors)
  - [Demo for BeanPostProcessor](#demo-for-beanpostprocessor)
    - [InstantiationAwareBeanPostProcessor](#instantiationawarebeanpostprocessor)
    - [CommonAnnotationBeanPostProcessor](#commonannotationbeanpostprocessor)
    - [AutowiredAnnotationBeanPostProcessor](#autowiredannotationbeanpostprocessor)
    - [AbstractAutoProxyCreator](#abstractautoproxycreator)

## Where load BeanPostProcessor

```java
// AbstractApplicationContext
// 在执行 refresh 方法的时候注册 BeanPostProcessors
@Override
public void refresh() throws BeansException, IllegalStateException {
// ...
// Register bean processors that intercept bean creation.
registerBeanPostProcessors(beanFactory);
// ...
}
```

## The hook method in BeanPostProcessor

```java
// BeanPostProcessor 中定义的方法
public interface BeanPostProcessor {

@Nullable
default Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
    return bean;
}

@Nullable
default Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
    return bean;
}
}
```

```java
// InstantiationAwareBeanPostProcessor
public interface InstantiationAwareBeanPostProcessor extends BeanPostProcessor {

@Nullable
default Object postProcessBeforeInstantiation(Class<?> beanClass, String beanName) throws BeansException {
return null;
}

default boolean postProcessAfterInstantiation(Object bean, String beanName) throws BeansException {
return true;
}

@Nullable
default PropertyValues postProcessPropertyValues(
PropertyValues pvs, PropertyDescriptor[] pds, Object bean, String beanName) throws BeansException {

return pvs;
}

}

```

## The load method PostProcessorRegistrationDelegate

> 初始 `BeanPostProcessor` 的工具类 (`delegate` -> `代表`)

```java
/**
 * Instantiate and register all BeanPostProcessor beans,
 * respecting explicit order if given.
 * <p>Must be called before any instantiation of application beans.
 */
protected void registerBeanPostProcessors(ConfigurableListableBeanFactory beanFactory) {
    PostProcessorRegistrationDelegate.registerBeanPostProcessors(beanFactory, this);
}
```

### PostProcessorRegistrationDelegate.registerBeanPostProcessors

```java
public static void registerBeanPostProcessors(ConfigurableListableBeanFactory beanFactory, AbstractApplicationContext applicationContext) {
   //
}
```

## Demo for BeanPostProcessor

### InstantiationAwareBeanPostProcessor

在 Bean 被创建的时候，Spring 会扫描所有 InstantiationAwareBeanPostProcessor 的实现类，进行依赖注入

`CommonAnnotationBeanPostProcessor` 和 `AutowiredAnnotationBeanPostProcessor` 注入实现类

下面会简单说明

### CommonAnnotationBeanPostProcessor

`CommonAnnotationBeanPostProcessor` 实现了 `JAX-WS` 规范中的注解的依赖注入，比如`javax.annotation.PostConstruct`,`javax.annotation.PreDestroy`,`javax.annotation.Resource`

### AutowiredAnnotationBeanPostProcessor

`AutowiredAnnotationBeanPostProcessor` 实现了 `InstantiationAwareBeanPostProcessorAdapter`(本质是 `BeanPostProcessor` 的加强版本实现) 在 Bean 初始化的时候(getBean) 的时候进行依赖注入，比如我们常用的 `Autowired` 和 `Value` 注解

```java
// AutowiredAnnotationBeanPostProcessor
// 主动注入的 注解 Autowired 和 Value
public AutowiredAnnotationBeanPostProcessor() {
  this.autowiredAnnotationTypes.add(Autowired.class);
  this.autowiredAnnotationTypes.add(Value.class);
  try {
    this.autowiredAnnotationTypes.add((Class<? extends Annotation>)
    ClassUtils.forName("javax.inject.Inject", AutowiredAnnotationBeanPostProcessor.class.getClassLoader()));
    logger.info("JSR-330 'javax.inject.Inject' annotation found and supported for autowiring");
  }
  catch (ClassNotFoundException ex) {
  // JSR-330 API not available - simply skip.
  }
}
```

最终会生产 `AutowiredMethodElement` 和 `AutowiredFieldElement` `方法注入`和`字段注入`,调用 `inject` 方法进入依赖的注入

方法调用链:

```java
AbstractAutowireCapableBeanFactory.postProcessPropertyValues
  -> AutowiredAnnotationBeanPostProcessor
   -> postProcessPropertyValues
    -> findAutowiringMetadata
     -> buildAutowiringMetadata
      -> AutowiredMethodElement/AutowiredFieldElement
       -> inject
```

### AbstractAutoProxyCreator

`Spring` 中的代理也是通过 `BeanPostProcessor` 的实现类 `AbstractAutoProxyCreator` 来实现的。这个后续再看
