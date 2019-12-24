# BeanDefinition

- [BeanDefinitionRegistry](spring-bean-definition-registry.md)

## Class implement BeanDefinition

- GenericBeanDefinition
- RootBeanDefinition
- ChildBeanDefinition

## AbstractBeanDefinition

## BeanDefinition define

```java
public interface BeanDefinition extends AttributeAccessor, BeanMetadataElement {

  String SCOPE_SINGLETON = ConfigurableBeanFactory.SCOPE_SINGLETON;
  
  String SCOPE_PROTOTYPE = ConfigurableBeanFactory.SCOPE_PROTOTYPE;
  
  int ROLE_APPLICATION = 0;

  int ROLE_SUPPORT = 1;
  
  int ROLE_INFRASTRUCTURE = 2;
  
  // Modifiable attributes

  void setParentName(@Nullable String parentName);

  @Nullable
  String getParentName();
  
  void setBeanClassName(@Nullable String beanClassName);
  
  @Nullable
  String getBeanClassName();

  void setScope(@Nullable String scope);
  
  @Nullable
  String getScope();

  void setLazyInit(boolean lazyInit);
  
  boolean isLazyInit();
  
  void setDependsOn(@Nullable String... dependsOn);
  
  @Nullable
  String[] getDependsOn();
  
  void setAutowireCandidate(boolean autowireCandidate);

  boolean isAutowireCandidate();

  void setPrimary(boolean primary);

  boolean isPrimary();

  void setFactoryBeanName(@Nullable String factoryBeanName);

  @Nullable
  String getFactoryBeanName();

  void setFactoryMethodName(@Nullable String factoryMethodName);

  @Nullable
  String getFactoryMethodName();

  ConstructorArgumentValues getConstructorArgumentValues();

  default boolean hasConstructorArgumentValues() {
    return !getConstructorArgumentValues().isEmpty();
  }

  MutablePropertyValues getPropertyValues();

  default boolean hasPropertyValues() {
    return !getPropertyValues().isEmpty();
  }

  // Read-only attributes

  boolean isSingleton();

  boolean isPrototype();

  boolean isAbstract();

  int getRole();

  @Nullable
  String getDescription();

  @Nullable
  String getResourceDescription();

  @Nullable
  BeanDefinition getOriginatingBeanDefinition();

}
```