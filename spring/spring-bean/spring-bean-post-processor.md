# BeanPostProcessor

- [BeanPostProcessor](#beanpostprocessor)
  - [where load BeanPostProcessor](#where-load-beanpostprocessor)
  - [PostProcessorRegistrationDelegate](#postprocessorregistrationdelegate)
    - [PostProcessorRegistrationDelegate.registerBeanPostProcessors](#postprocessorregistrationdelegateregisterbeanpostprocessors)
    - [beanFactory.getBean](#beanfactorygetbean)

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

## PostProcessorRegistrationDelegate

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
