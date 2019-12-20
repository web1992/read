# AutowiredAnnotationBeanPostProcessor

- [AutowiredAnnotationBeanPostProcessor](#autowiredannotationbeanpostprocessor)
  - [Class define](#class-define)
  - [InstantiationAwareBeanPostProcessorAdapter](#instantiationawarebeanpostprocessoradapter)
  - [AutowiredAnnotationBeanPostProcessor.init](#autowiredannotationbeanpostprocessorinit)
  - [AutowiredAnnotationBeanPostProcessor.postProcessPropertyValues](#autowiredannotationbeanpostprocessorpostprocesspropertyvalues)
  - [AutowiredAnnotationBeanPostProcessor.buildAutowiringMetadata](#autowiredannotationbeanpostprocessorbuildautowiringmetadata)
  - [InjectionMetadata](#injectionmetadata)
  - [InjectedElement.inject](#injectedelementinject)
  - [ConfigurableListableBeanFactory.resolveDependency](#configurablelistablebeanfactoryresolvedependency)

## Class define

```java
public class AutowiredAnnotationBeanPostProcessor extends InstantiationAwareBeanPostProcessorAdapter
implements MergedBeanDefinitionPostProcessor, PriorityOrdered, BeanFactoryAware {

}
```

## InstantiationAwareBeanPostProcessorAdapter

`InstantiationAwareBeanPostProcessorAdapter` 适配器

## AutowiredAnnotationBeanPostProcessor.init

```java
// AutowiredAnnotationBeanPostProcessor 在初始的时候
// 把 Autowired Value Inject 三个注解放入到 Set<Annotation> autowiredAnnotationTypes 中
// 在后续执行 buildAutowiringMetadata 的时候会找被它们三个[注解标注]的方法和字段
// 最后执行 InjectionMetadata.inject 方法进行依赖的注入
// 而后通过 beanFactory.resolveDependency 寻找需要注入的对象
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

## AutowiredAnnotationBeanPostProcessor.postProcessPropertyValues

```java
@Override
public PropertyValues postProcessPropertyValues(
    PropertyValues pvs, PropertyDescriptor[] pds, Object bean, String beanName) throws BeanCreationException {
  InjectionMetadata metadata = findAutowiringMetadata(beanName, bean.getClass(), pvs);
  try {
    metadata.inject(bean, beanName, pvs);
  }
  catch (BeanCreationException ex) {
    throw ex;
  }
  catch (Throwable ex) {
    throw new BeanCreationException(beanName, "Injection of autowired dependencies failed", ex);
  }
  return pvs;
}
```

## AutowiredAnnotationBeanPostProcessor.buildAutowiringMetadata

```java
// 省略其他代码...
// 使用反射 生成 AutowiredFieldElement
ReflectionUtils.doWithLocalFields

// 省略其他代码...
// 使用反射 生成 AutowiredMethodElement
ReflectionUtils.doWithLocalMethods
```

## InjectionMetadata

`findAutowiringMetadata`

```java
public void inject(Object target, @Nullable String beanName, @Nullable PropertyValues pvs) throws Throwable {
  Collection<InjectedElement> checkedElements = this.checkedElements;
  Collection<InjectedElement> elementsToIterate =
      (checkedElements != null ? checkedElements : this.injectedElements);
  if (!elementsToIterate.isEmpty()) {
    for (InjectedElement element : elementsToIterate) {
      if (logger.isDebugEnabled()) {
        logger.debug("Processing injected element of bean '" + beanName + "': " + element);
      }
      // AutowiredFieldElement or AutowiredMethodElement
      element.inject(target, beanName, pvs);
    }
  }
}
```

## InjectedElement.inject

```java
/**
 * Either this or {@link #getResourceToInject} needs to be overridden.
 */
protected void inject(Object target, @Nullable String requestingBeanName, @Nullable PropertyValues pvs)
  throws Throwable {
if (this.isField) {
  Field field = (Field) this.member;
  ReflectionUtils.makeAccessible(field);
  // 字段注入
  field.set(target, getResourceToInject(target, requestingBeanName));
}
else {
  if (checkPropertySkipping(pvs)) {
    return;
  }
  try {
    Method method = (Method) this.member;
    ReflectionUtils.makeAccessible(method);
    // 方法注入
    method.invoke(target, getResourceToInject(target, requestingBeanName));
  }
  catch (InvocationTargetException ex) {
    throw ex.getTargetException();
  }
}
}
```

## ConfigurableListableBeanFactory.resolveDependency

```java
// resolveDependency -> doResolveDependency -> resolveCandidate
// org.springframework.beans.factory.config.DependencyDescriptor.resolveCandidate
public Object resolveCandidate(String beanName, Class<?> requiredType, BeanFactory beanFactory)
   throws BeansException {
   return beanFactory.getBean(beanName);
}
```
