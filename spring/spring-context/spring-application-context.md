# ApplicationContext

- ListableBeanFactory
- ResourceLoader
- MessageSource
- ApplicationEventPublisher
- ResourcePatternResolver

## ApplicationContext define

```java
public interface ApplicationContext extends EnvironmentCapable, ListableBeanFactory, HierarchicalBeanFactory,
    MessageSource, ApplicationEventPublisher, ResourcePatternResolver {

}
```

![ClassPathXmlApplicationContext](../images/spring-ClassPathXmlApplicationContext.png)

## AbstractApplicationContext.refresh

`refresh` 可以认为是 `Spring` 容器的启动的入口,类似 `Java` 的 `main` 方法

```java
@Override
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

## List

- [ApplicationContext](https://blog.csdn.net/sid1109217623/article/details/83583411)
