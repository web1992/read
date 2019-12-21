# BeanFactoryPostProcessor

与 [BeanPostProcessor](./spring-bean-post-processor.md) 类似

- [BeanFactoryPostProcessor](#beanfactorypostprocessor)
  - [When load BeanFactoryPostProcessor](#when-load-beanfactorypostprocessor)
  - [The hook method postProcessBeforeInitialization and postProcessAfterInitialization](#the-hook-method-postprocessbeforeinitialization-and-postprocessafterinitialization)
  - [The load method PostProcessorRegistrationDelegate](#the-load-method-postprocessorregistrationdelegate)
    - [PostProcessorRegistrationDelegate-registerBeanPostProcessors](#postprocessorregistrationdelegate-registerbeanpostprocessors)
  - [BeanDefinitionRegistry](#beandefinitionregistry)

## When load BeanFactoryPostProcessor

```java
// AbstractApplicationContext
@Override
public void refresh() throws BeansException, IllegalStateException {

// ...
// Invoke factory processors registered as beans in the context.
invokeBeanFactoryPostProcessors(beanFactory)
// ...

}
```

## The hook method postProcessBeforeInitialization and postProcessAfterInitialization

```java
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

## The load method PostProcessorRegistrationDelegate

> `PostProcessorRegistrationDelegate` 是一个工具类

`PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(beanFactory, getBeanFactoryPostProcessors());`

> 初始化实现了 `BeanFactoryPostProcessor`和 `BeanDefinitionRegistry` 接口的类

### PostProcessorRegistrationDelegate-registerBeanPostProcessors

```java
public static void registerBeanPostProcessors(
ConfigurableListableBeanFactory beanFactory, AbstractApplicationContext applicationContext) {

}
```

## BeanDefinitionRegistry
