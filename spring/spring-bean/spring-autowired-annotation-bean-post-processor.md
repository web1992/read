# AutowiredAnnotationBeanPostProcessor

## Class

```java
public class AutowiredAnnotationBeanPostProcessor extends InstantiationAwareBeanPostProcessorAdapter
implements MergedBeanDefinitionPostProcessor, PriorityOrdered, BeanFactoryAware {

}
```

## AutowiredAnnotationBeanPostProcessor.init

```java
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

## setAutowiredAnnotationType

```java
/**
 * Set the 'autowired' annotation type, to be used on constructors, fields,
 * setter methods, and arbitrary config methods.
 * <p>The default autowired annotation types are the Spring-provided
 * {@link Autowired @Autowired} and {@link Value @Value} annotations as well
 * as JSR-330's {@link javax.inject.Inject @Inject} annotation, if available.
 * <p>This setter property exists so that developers can provide their own
 * (non-Spring-specific) annotation type to indicate that a member is supposed
 * to be autowired.
 */
public void setAutowiredAnnotationType(Class<? extends Annotation> autowiredAnnotationType) {
   Assert.notNull(autowiredAnnotationType, "'autowiredAnnotationType' must not be null");
   this.autowiredAnnotationTypes.clear();
   this.autowiredAnnotationTypes.add(autowiredAnnotationType);
}
```

## postProcessPropertyValues

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
  field.set(target, getResourceToInject(target, requestingBeanName));
}
else {
  if (checkPropertySkipping(pvs)) {
    return;
  }
  try {
    Method method = (Method) this.member;
    ReflectionUtils.makeAccessible(method);
    method.invoke(target, getResourceToInject(target, requestingBeanName));
  }
  catch (InvocationTargetException ex) {
    throw ex.getTargetException();
  }
}
}
```
