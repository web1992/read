# Spring boot AutoConfiguration

`Spring` 自动配置原理

- [Spring boot AutoConfiguration](#spring-boot-autoconfiguration)
  - [AutoConfigurationPackages.Registrar](#autoconfigurationpackagesregistrar)
  - [AutoConfigurationImportSelector](#autoconfigurationimportselector)
    - [getAutoConfigurationEntry](#getautoconfigurationentry)
    - [getCandidateConfigurations](#getcandidateconfigurations)
  - [ConfigurationClassParser](#configurationclassparser)
  - [ConfigurationClassBeanDefinitionReader](#configurationclassbeandefinitionreader)
  - [ConditionEvaluator](#conditionevaluator)
  - [SpringBootCondition and FilteringSpringBootCondition](#springbootcondition-and-filteringspringbootcondition)
    - [OnBeanCondition](#onbeancondition)
    - [OnClassCondition](#onclasscondition)
    - [OnWebApplicationCondition](#onwebapplicationcondition)

## AutoConfigurationPackages.Registrar

## AutoConfigurationImportSelector

### getAutoConfigurationEntry

### getCandidateConfigurations

```java
protected List<String> getCandidateConfigurations(AnnotationMetadata metadata, AnnotationAttributes attributes) {
   List<String> configurations = SpringFactoriesLoader.loadFactoryNames(getSpringFactoriesLoaderFactoryClass(),
         getBeanClassLoader());
   Assert.notEmpty(configurations, "No auto configuration classes found in META-INF/spring.factories. If you "
         + "are using a custom packaging, make sure that file is correct.");
   return configurations;
}
```

## ConfigurationClassParser

## ConfigurationClassBeanDefinitionReader

```java
loadBeanDefinitionsForBeanMethod
      -> conditionEvaluator.shouldSkip
      -> condition.matches
```

## ConditionEvaluator

## SpringBootCondition and FilteringSpringBootCondition

### OnBeanCondition

### OnClassCondition

### OnWebApplicationCondition
