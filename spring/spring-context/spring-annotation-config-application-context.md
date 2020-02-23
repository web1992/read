# AnnotationConfigApplicationContext

- [AnnotationConfigApplicationContext](#annotationconfigapplicationcontext)
  - [AnnotationConfigApplicationContext init](#annotationconfigapplicationcontext-init)
  - [ClassPathBeanDefinitionScanner](#classpathbeandefinitionscanner)
    - [ClassPathBeanDefinitionScanner-doScan](#classpathbeandefinitionscanner-doscan)
    - [AnnotationTypeFilter](#annotationtypefilter)
  - [AbstractApplicationContext](#abstractapplicationcontext)
    - [refresh](#refresh)

## AnnotationConfigApplicationContext init

```java
// 最简单的用法例子
// 创建 AnnotationConfigApplicationContext
AnnotationConfigApplicationContext context;
context = new AnnotationConfigApplicationContext();
// 扫描
context.scan("cn.web1992.spring.demo");
//  刷新
context.refresh();
// do some thing ...
// 执行 getBean 进行其他操作等等
```

```java
// 在创建 AnnotationConfigApplicationContext 的时候，会自动创建
// AnnotatedBeanDefinitionReader 和 ClassPathBeanDefinitionScanner
// 进行 bean 的扫描
public AnnotationConfigApplicationContext() {
this.reader = new AnnotatedBeanDefinitionReader(this);
this.scanner = new ClassPathBeanDefinitionScanner(this);
}
```

## ClassPathBeanDefinitionScanner

### ClassPathBeanDefinitionScanner-doScan

```java
public class ClassPathBeanDefinitionScanner extends ClassPathScanningCandidateComponentProvider {
// ...
}
```

### AnnotationTypeFilter

```java
// ClassPathScanningCandidateComponentProvider
protected void registerDefaultFilters() {
    // Component 这里对有Component的类进行注册
    this.includeFilters.add(new AnnotationTypeFilter(Component.class));
    ClassLoader cl = ClassPathScanningCandidateComponentProvider.class.getClassLoader();
    try {
    this.includeFilters.add(new AnnotationTypeFilter(
    ((Class<? extends Annotation>) ClassUtils.forName("javax.annotation.ManagedBean", cl)), false));
    logger.debug("JSR-250 'javax.annotation.ManagedBean' found and supported for component scanning");
    }
    catch (ClassNotFoundException ex) {
    // JSR-250 1.1 API (as included in Java EE 6) not available - simply skip.
    }
    try {
    this.includeFilters.add(new AnnotationTypeFilter(
    ((Class<? extends Annotation>) ClassUtils.forName("javax.inject.Named", cl)), false));
    logger.debug("JSR-330 'javax.inject.Named' annotation found and supported for component scanning");
    }
    catch (ClassNotFoundException ex) {
    // JSR-330 API not available - simply skip.
    }
}
```

## AbstractApplicationContext

### refresh

```java
public void refresh() throws BeansException, IllegalStateException {
synchronized (this.startupShutdownMonitor) {
    // Prepare this context for refreshing.
    prepareRefresh();
    // Tell the subclass to refresh the internal bean factory.
    ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();
    // Prepare the bean factory for use in this context.
    prepareBeanFactory(beanFactory);
    try {
    // Allows post-processing of the bean factory in context subclasses.
    postProcessBeanFactory(beanFactory);
    // Invoke factory processors registered as beans in the context.
    invokeBeanFactoryPostProcessors(beanFactory);
    // Register bean processors that intercept bean creation.
    registerBeanPostProcessors(beanFactory);
    // Initialize message source for this context.
    initMessageSource();
    // Initialize event multicaster for this context.
    initApplicationEventMulticaster();
    // Initialize other special beans in specific context subclasses.
    onRefresh();
    // Check for listener beans and register them.
    registerListeners();
    // Instantiate all remaining (non-lazy-init) singletons.
    finishBeanFactoryInitialization(beanFactory);
    // Last step: publish corresponding event.
    finishRefresh();
    }
    catch (BeansException ex) {
    if (logger.isWarnEnabled()) {
    logger.warn("Exception encountered during context initialization - " +
    "cancelling refresh attempt: " + ex);
    }
    // Destroy already created singletons to avoid dangling resources.
    destroyBeans();
    // Reset 'active' flag.
    cancelRefresh(ex);
    // Propagate exception to caller.
    throw ex;
    }
    finally {
    // Reset common introspection caches in Spring's core, since we
    // might not ever need metadata for singleton beans anymore...
    resetCommonCaches();
    }
}
}
```
