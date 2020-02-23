# BeanFactoryPostProcessor

与 [BeanPostProcessor](./spring-bean-post-processor.md) 类似

- [BeanFactoryPostProcessor](#beanfactorypostprocessor)
  - [When load BeanFactoryPostProcessor](#when-load-beanfactorypostprocessor)
  - [The hook method postProcessBeanFactory](#the-hook-method-postprocessbeanfactory)
  - [The load method PostProcessorRegistrationDelegate](#the-load-method-postprocessorregistrationdelegate)
    - [PostProcessorRegistrationDelegate-registerBeanPostProcessors](#postprocessorregistrationdelegate-registerbeanpostprocessors)
  - [PropertyResourceConfigurer](#propertyresourceconfigurer)

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

> `PostProcessorRegistrationDelegate` 是一个工具类

`PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(beanFactory, getBeanFactoryPostProcessors());`

> 初始化实现了 `BeanFactoryPostProcessor`和 `BeanDefinitionRegistry` 接口的类

### PostProcessorRegistrationDelegate-registerBeanPostProcessors

```java
public static void registerBeanPostProcessors(
ConfigurableListableBeanFactory beanFactory, AbstractApplicationContext applicationContext) {

}
```

## PropertyResourceConfigurer

`PropertyResourceConfigurer` Spring 实现 `${}` 占位符注入的 `BeanFactoryPostProcessor` 一种实现
