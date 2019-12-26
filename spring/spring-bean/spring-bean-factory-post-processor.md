# BeanFactoryPostProcessor

与 [BeanPostProcessor](./spring-bean-post-processor.md) 类似

- [BeanFactoryPostProcessor](#beanfactorypostprocessor)
  - [When load BeanFactoryPostProcessor](#when-load-beanfactorypostprocessor)
  - [The hook method postProcessBeforeInitialization and postProcessAfterInitialization](#the-hook-method-postprocessbeforeinitialization-and-postprocessafterinitialization)
  - [The load method PostProcessorRegistrationDelegate](#the-load-method-postprocessorregistrationdelegate)
    - [PostProcessorRegistrationDelegate-registerBeanPostProcessors](#postprocessorregistrationdelegate-registerbeanpostprocessors)
  - [Demo for BeanFactoryPostProcessor](#demo-for-beanfactorypostprocessor)
  - [BeanDefinitionRegistry](#beandefinitionregistry)

## When load BeanFactoryPostProcessor

> `BeanFactoryPostProcessor` 的作用,在 `AbstractApplicationContext.refresh` 中有下面的注释

```java
/**
 * Allows for custom modification of an application context's bean definitions,
 * adapting the bean property values of the context's underlying bean factory.
 *
 * <p>Application contexts can auto-detect BeanFactoryPostProcessor beans in
 * their bean definitions and apply them before any other beans get created.
 *
 * <p>Useful for custom config files targeted at system administrators that
 * override bean properties configured in the application context.
 *
 * <p>See PropertyResourceConfigurer and its concrete implementations
 * for out-of-the-box solutions that address such configuration needs.
 *
 * <p>A BeanFactoryPostProcessor may interact with and modify bean
 * definitions, but never bean instances. Doing so may cause premature bean
 * instantiation, violating the container and causing unintended side-effects.
 * If bean instance interaction is required, consider implementing
 * {@link BeanPostProcessor} instead.
 *
 * @author Juergen Hoeller
 * @since 06.07.2003
 * @see BeanPostProcessor
 * @see PropertyResourceConfigurer
 */
```

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

## Demo for BeanFactoryPostProcessor

`BeanFactoryPostProcessor` 实例

## BeanDefinitionRegistry
