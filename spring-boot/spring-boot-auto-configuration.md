# Spring boot AutoConfiguration

`Spring` 自动配置原理

- [Spring boot AutoConfiguration](#spring-boot-autoconfiguration)
  - [Spring Boot Appliaction](#spring-boot-appliaction)
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

## Spring Boot Appliaction

先看下一个简单的 `Spring Boot` 应用，使用的注解

```java
@SpringBootApplication
public class SpringBootsApplication {

     public static void main(String[] args) {
          SpringApplication.run(SpringBootsApplication.class, args);
     }

}

// SpringBootApplication
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = { @Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
                   @Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public @interface SpringBootApplication {

}
// SpringBootConfiguration
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Configuration
public @interface SpringBootConfiguration {

}
// EnableAutoConfiguration
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@AutoConfigurationPackage
@Import(AutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration {

}

// AutoConfigurationPackage
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@Import(AutoConfigurationPackages.Registrar.class)
public @interface AutoConfigurationPackage {

}
```

上面的注解虽然很多，但是核心的注解其实就是 `@Configuration` + `@Import` +`@ComponentScan`

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
