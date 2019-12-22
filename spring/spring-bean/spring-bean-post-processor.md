# BeanPostProcessor

与 [BeanFactoryPostProcessor](./spring-bean-factory-post-processor.md) 类似

- [BeanPostProcessor](#beanpostprocessor)
  - [where load BeanPostProcessor](#where-load-beanpostprocessor)
  - [The hook method postProcessBeanFactory](#the-hook-method-postprocessbeanfactory)
  - [The load method PostProcessorRegistrationDelegate](#the-load-method-postprocessorregistrationdelegate)
    - [PostProcessorRegistrationDelegate.registerBeanPostProcessors](#postprocessorregistrationdelegateregisterbeanpostprocessors)
    - [beanFactory.getBean](#beanfactorygetbean)
  - [Demo for BeanPostProcessor](#demo-for-beanpostprocessor)

## where load BeanPostProcessor

```java
// AbstractApplicationContext
@Override
public void refresh() throws BeansException, IllegalStateException {
// ...
// Register bean processors that intercept bean creation.
registerBeanPostProcessors(beanFactory);
// ...
}
```

## The hook method postProcessBeanFactory

```java
@FunctionalInterface
public interface BeanFactoryPostProcessor {
 /**
  * Modify the application context's internal bean factory after its standard
  * initialization. All bean definitions will have been loaded, but no beans
  * will have been instantiated yet. This allows for overriding or adding
  * properties even to eager-initializing beans.
  * @param beanFactory the bean factory used by the application context
  * @throws org.springframework.beans.BeansException in case of errors
  */
 void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException;
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

### beanFactory.getBean

在 `registerBeanPostProcessors` 方法中调用了 `BeanFactory` 的 `getBean` 方法,那么 `BeanFactory` 中的 `bean` 是从哪里来的呢？

## Demo for BeanPostProcessor
