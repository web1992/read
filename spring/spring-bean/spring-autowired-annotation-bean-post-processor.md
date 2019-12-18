# AutowiredAnnotationBeanPostProcessor

## Class

```java
public class AutowiredAnnotationBeanPostProcessor extends InstantiationAwareBeanPostProcessorAdapter
implements MergedBeanDefinitionPostProcessor, PriorityOrdered, BeanFactoryAware {

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
