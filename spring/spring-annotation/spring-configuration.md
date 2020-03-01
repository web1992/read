# @Configuration

- [@Configuration](#configuration)
  - [整体思路](#%e6%95%b4%e4%bd%93%e6%80%9d%e8%b7%af)
  - [Define of Configuration](#define-of-configuration)
  - [demo](#demo)
  - [AnnotationConfigApplicationContext](#annotationconfigapplicationcontext)
  - [ConfigurationClassParser](#configurationclassparser)
  - [ConfigurationClassPostProcessor](#configurationclasspostprocessor)
    - [postProcessBeanDefinitionRegistry](#postprocessbeandefinitionregistry)
    - [postProcessBeanFactory](#postprocessbeanfactory)
    - [ConfigurationClassEnhancer](#configurationclassenhancer)

## 整体思路

1. 使用 `ConfigurationClassPostProcessor` 拦截 Spring 的 `postProcessBeanDefinitionRegistry`和 `postProcessBeanFactory` 两个方法
2. 负责 `postProcessBeanDefinitionRegistry` 创建 `BeanDef`
3. `postProcessBeanFactory` 负责使用 `CGLIB` 加强`BEAN`
4. 解析类，扫描所有 `@Bean` 方法的，创建 `ConfigurationClassBeanDefinition` 并执行 `registry.registerBeanDefinition` 注册 `BeanDef`
5. 使用 `CGLIB` 对 `@Configuration` 注解类进行代理增强,目的是拦截所有有 `@Bean` 注解的方法调用
6. 注入 `BeanFactory` 当调用有 `@Bean` 注解的方法时，就去 `BeanFactory` 中执行 `getBean` 方法走 `Bean` 创建流程

## Define of Configuration

```java
// Configuration 的定义
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Component
public @interface Configuration {

@AliasFor(annotation = Component.class)
String value() default "";

}
```

## demo

```java
// 用这个例子来分析 @Configuration 的解析过程
AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext();
     ctx.register(AppConfig.class);
     ctx.refresh();
     MyBean myBean = ctx.getBean(MyBean.class);
     System.out.println(myBean);
 }
static class MyBean {
     String name;
     public MyBean(String name) {
         System.out.println("MyBean init");
         this.name = name;
     }
     @Override
     public String toString() {
         return "MyBean{" +
                 "name='" + name + '\'' +
                 '}';
     }
 }
 @Configuration
 static class AppConfig {
     @Bean
     MyBean getBean() {
         return new MyBean("Spring");
     }
 }
```

## AnnotationConfigApplicationContext

`ConfigurationClassPostProcessor` 在 `AnnotationConfigApplicationContext` 创建的时候，被当做 `Bean` 加载

具体的代码流程如下：

```java
AnnotationConfigApplicationContext
  -> new AnnotatedBeanDefinitionReader(this);
   -> AnnotationConfigUtils.registerAnnotationConfigProcessors(this.registry);
    -> registerAnnotationConfigProcessors
     -> RootBeanDefinition def = new RootBeanDefinition(ConfigurationClassPostProcessor.class);
```

## ConfigurationClassParser

## ConfigurationClassPostProcessor

> `ConfigurationClassPostProcessor` 的定义,本质是一个 `BeanFactoryPostProcessor`

```java
// ConfigurationClassPostProcessor
public class ConfigurationClassPostProcessor implements BeanDefinitionRegistryPostProcessor,
      PriorityOrdered, ResourceLoaderAware, BeanClassLoaderAware, EnvironmentAware {
}
// BeanDefinitionRegistryPostProcessor
// 实现 BeanFactoryPostProcessor 就是为了执行 postProcessBeanFactory 方法
// BeanDefinitionRegistryPostProcessor 但是会在上面的方法之前执行
// 具体的逻辑代码在 PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors 中
public interface BeanDefinitionRegistryPostProcessor extends BeanFactoryPostProcessor {
    void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException;
}
```

### postProcessBeanDefinitionRegistry

```java
// processConfigBeanDefinitions
// Parse each @Configuration class
ConfigurationClassParser parser = new ConfigurationClassParser(
this.metadataReaderFactory, this.problemReporter, this.environment,
this.resourceLoader, this.componentScanBeanNameGenerator, registry);
```

会创建 `ConfigurationClassParser` 对象解析`@Configuration`的注解,注册 `BeanDef`

### postProcessBeanFactory

`postProcessBeanFactory` -> `enhanceConfigurationClasses` -> `ConfigurationClassEnhancer.enhance`

这里会对 `@Configuration` 使用 `CGLIB` 进行代理增强

### ConfigurationClassEnhancer

这里说下为什么对 `@Bean` 注解的方法进行代理增强，引用存在内部的方法调用，比如 `this.getBeanMethod`

如果不进行代理，那么会再次执行这个方法，创建一个新的对象，而这个对象不是由 `Spring` 容器维护的。为了解决内部调用

的问题，因此引入了 `CGLIB` 增强，对这个方法进行拦截，都去执行 `getBean` 方法，从容器中获取 `Bean` 对象

可以通过 `@Configuration` 中的 `proxyBeanMethods=false` 关闭这个代理增强

```java
// The callbacks to use. Note that these callbacks must be stateless.
private static final Callback[] CALLBACKS = new Callback[] {
 new BeanMethodInterceptor(),
 new BeanFactoryAwareMethodInterceptor(),
 NoOp.INSTANCE
};

// BeanFactoryAwareMethodInterceptor 负责注入 BeanFactory 对象
// BeanMethodInterceptor 负责拦截方法调用，从 BeanFactory 加载创建 Bean 对象
/**
 * Creates a new CGLIB {@link Enhancer} instance.
 */
private Enhancer newEnhancer(Class<?> configSuperClass, @Nullable ClassLoader classLoader) {
  Enhancer enhancer = new Enhancer();
  enhancer.setSuperclass(configSuperClass);
  enhancer.setInterfaces(new Class<?>[] {EnhancedConfiguration.class});
  enhancer.setUseFactory(false);
  enhancer.setNamingPolicy(SpringNamingPolicy.INSTANCE);
  enhancer.setStrategy(new BeanFactoryAwareGeneratorStrategy(classLoader));
  enhancer.setCallbackFilter(CALLBACK_FILTER);
  enhancer.setCallbackTypes(CALLBACK_FILTER.getCallbackTypes());
  return enhancer;
}

// EnhancedConfiguration 目的就是集成 BeanFactoryAware
// 通过 BeanFactoryAwareMethodInterceptor 调用 setBeanFactory 方法
// 进行 BeanFactory 对象的注入
public interface EnhancedConfiguration extends BeanFactoryAware {
}
```
