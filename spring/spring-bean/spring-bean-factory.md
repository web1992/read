# BeanFactory

- [BeanFactory](#beanfactory)
  - [BeanFactory Summary](#beanfactory-summary)
  - [The Class implement BeanFactory](#the-class-implement-beanfactory)
  - [DefaultListableBeanFactory](#defaultlistablebeanfactory)
  - [AbstractAutowireCapableBeanFactory.doCreateBean](#abstractautowirecapablebeanfactorydocreatebean)
  - [AbstractBeanFactory.doGetBean](#abstractbeanfactorydogetbean)
  - [FactoryBean](#factorybean)
  - [Reference](#reference)

## BeanFactory Summary

`BeanFactory` 主要负责 `Bean` 的实例的`加载`和`初始化`,具体流程可以参考图   [spring-bean-load.png](../images/spring-bean-load.png) & [spring-bean-init.png](../images/spring-bean-init.png)

## The Class implement BeanFactory

> 实现了 BeanFactory 的类（主要的）

| 实现类                         | 描述                                                                              |
| ------------------------------ | --------------------------------------------------------------------------------- |
| ClassPathXmlApplicationContext | 虽然实现了BeanFactory，但是具体工作的是 DefaultListableBeanFactory                |
|                                | ApplicationContext 把 BeanFactory 作为变量,通过 getBeanFactory 方法进行获取和调用 |  |
| DefaultListableBeanFactory     | 负责具体工作的 BeanFactory                                         |

具体的调用链：

```java
AbstractApplicationContext.refresh

-> AbstractApplicationContext.obtainFreshBeanFactory

-> AbstractRefreshableApplicationContext.refreshBeanFactory

-> AbstractRefreshableApplicationContext.createBeanFactory
```

```java
// 在 createBeanFactory 方法中进行了 new 操作
// 后续在 XXXAppliactionContext 中获取 BeanFactory 都是通过 getBeanFactory 方法
protected DefaultListableBeanFactory createBeanFactory() {
   return new DefaultListableBeanFactory(getInternalParentBeanFactory());
}

// AbstractRefreshableApplicationContext.refreshBeanFactory
// 而后把 new 生成的对象作为 ApplicationContext 的成员变量
synchronized (this.beanFactoryMonitor) {
    this.beanFactory = beanFactory;
}
```

## DefaultListableBeanFactory

`DefaultListableBeanFactory` 是在 `XXXXAppliactionContext` 初始化的时候进行初始化的

## AbstractAutowireCapableBeanFactory.doCreateBean

## AbstractBeanFactory.doGetBean

## FactoryBean

- [BeanFactory `VS` FactoryBean](spring-factory-bean.md)

`BeanFactory` 是 `Spring` 中的 `bean` 容器，管理所有的 `Bean` 对象

`FactoryBean` 用来创建 `bean` 对象，比如 `mybatis` 用 [MapperFactoryBean](.././../java/mybatis/mybatis-mapper-factory-bean.md) 来创建 `Mapper` 对象

## Reference

- [https://www.cnblogs.com/aspirant/p/9082858.html](https://www.cnblogs.com/aspirant/p/9082858.html)
