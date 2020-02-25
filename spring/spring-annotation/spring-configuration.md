# @Configuration

[ClassPathBeanDefinitionScanner 分析](.././spring-context/spring-class-path-bean-definition-scanner.md)

- [@Configuration](#configuration)
  - [具体流程](#%e5%85%b7%e4%bd%93%e6%b5%81%e7%a8%8b)
  - [Define of Configuration](#define-of-configuration)
  - [demo](#demo)
  - [AnnotationConfigApplicationContext](#annotationconfigapplicationcontext)
  - [ConfigurationClassPostProcessor](#configurationclasspostprocessor)
    - [postProcessBeanDefinitionRegistry](#postprocessbeandefinitionregistry)
  - [ConfigurationClassParser parse](#configurationclassparser-parse)
    - [doProcessConfigurationClass](#doprocessconfigurationclass)
  - [enhanceConfigurationClasses](#enhanceconfigurationclasses)
  - [ConfigurationClass](#configurationclass)

## 具体流程

1. 使用 `ConfigurationClassPostProcessor` 拦截 Spring 的 `BeanPostProcessor` 过程
2. 使用 `CGLIB` 对 `@Configuration` 注解类进行代理增强，目的是拦截所有有 `@Bean` 注解的方法调用
3. 解析类，扫描所有@Bean 方法的，创建 `ConfigurationClassBeanDefinition` 并执行 `registry.registerBeanDefinition` 注册 `BeanDef`

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

## ConfigurationClassPostProcessor

> `ConfigurationClassPostProcessor` 的定义,本质是一个 `BeanFactoryPostProcessor`

```java
// ConfigurationClassPostProcessor
public class ConfigurationClassPostProcessor implements BeanDefinitionRegistryPostProcessor,
      PriorityOrdered, ResourceLoaderAware, BeanClassLoaderAware, EnvironmentAware {
}
// BeanDefinitionRegistryPostProcessor
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

会创建 `ConfigurationClassParser` 对象解析`@Configuration`的注解

## ConfigurationClassParser parse

```java
do {
    // 解析
    // 验证
   parser.parse(candidates);
   parser.validate();
   Set<ConfigurationClass> configClasses = new LinkedHashSet<>(parser.getConfigurationClasses());
   configClasses.removeAll(alreadyParsed);
   // Read the model and create bean definitions based on its content
   if (this.reader == null) {
      this.reader = new ConfigurationClassBeanDefinitionReader(
            registry, this.sourceExtractor, this.resourceLoader, this.environment,
            this.importBeanNameGenerator, parser.getImportRegistry());
   }
   this.reader.loadBeanDefinitions(configClasses);
   alreadyParsed.addAll(configClasses);
   candidates.clear();
   if (registry.getBeanDefinitionCount() > candidateNames.length) {
      String[] newCandidateNames = registry.getBeanDefinitionNames();
      Set<String> oldCandidateNames = new HashSet<>(Arrays.asList(candidateNames));
      Set<String> alreadyParsedClasses = new HashSet<>();
      for (ConfigurationClass configurationClass : alreadyParsed) {
         alreadyParsedClasses.add(configurationClass.getMetadata().getClassName());
      }
      for (String candidateName : newCandidateNames) {
         if (!oldCandidateNames.contains(candidateName)) {
            BeanDefinition bd = registry.getBeanDefinition(candidateName);
            if (ConfigurationClassUtils.checkConfigurationClassCandidate(bd, this.metadataReaderFactory) &&
                  !alreadyParsedClasses.contains(bd.getBeanClassName())) {
               candidates.add(new BeanDefinitionHolder(bd, candidateName));
            }
         }
      }
      candidateNames = newCandidateNames;
   }
}
while (!candidates.isEmpty());
```

### doProcessConfigurationClass

```java
// ConfigurationClassParser
@Nullable
protected final SourceClass doProcessConfigurationClass(ConfigurationClass configClass, SourceClass sourceClass)
      throws IOException {
   // Recursively process any member (nested) classes first
   processMemberClasses(configClass, sourceClass);
   // Process any @PropertySource annotations
   for (AnnotationAttributes propertySource : AnnotationConfigUtils.attributesForRepeatable(
         sourceClass.getMetadata(), PropertySources.class,
         org.springframework.context.annotation.PropertySource.class)) {
      if (this.environment instanceof ConfigurableEnvironment) {
         processPropertySource(propertySource);
      }
      else {
         logger.warn("Ignoring @PropertySource annotation on [" + sourceClass.getMetadata().getClassName() +
               "]. Reason: Environment must implement ConfigurableEnvironment");
      }
   }
   // Process any @ComponentScan annotations
   Set<AnnotationAttributes> componentScans = AnnotationConfigUtils.attributesForRepeatable(
         sourceClass.getMetadata(), ComponentScans.class, ComponentScan.class);
   if (!componentScans.isEmpty() &&
         !this.conditionEvaluator.shouldSkip(sourceClass.getMetadata(), ConfigurationPhase.REGISTER_BEAN)) {
      for (AnnotationAttributes componentScan : componentScans) {
         // The config class is annotated with @ComponentScan -> perform the scan immediately
         Set<BeanDefinitionHolder> scannedBeanDefinitions =
               this.componentScanParser.parse(componentScan, sourceClass.getMetadata().getClassName());
         // Check the set of scanned definitions for any further config classes and parse recursively if needed
         for (BeanDefinitionHolder holder : scannedBeanDefinitions) {
            BeanDefinition bdCand = holder.getBeanDefinition().getOriginatingBeanDefinition();
            if (bdCand == null) {
               bdCand = holder.getBeanDefinition();
            }
            if (ConfigurationClassUtils.checkConfigurationClassCandidate(bdCand, this.metadataReaderFactory)) {
               parse(bdCand.getBeanClassName(), holder.getBeanName());
            }
         }
      }
   }
   // Process any @Import annotations
   processImports(configClass, sourceClass, getImports(sourceClass), true);
   // Process any @ImportResource annotations
   AnnotationAttributes importResource =
         AnnotationConfigUtils.attributesFor(sourceClass.getMetadata(), ImportResource.class);
   if (importResource != null) {
      String[] resources = importResource.getStringArray("locations");
      Class<? extends BeanDefinitionReader> readerClass = importResource.getClass("reader");
      for (String resource : resources) {
         String resolvedResource = this.environment.resolveRequiredPlaceholders(resource);
         configClass.addImportedResource(resolvedResource, readerClass);
      }
   }
   // Process individual @Bean methods
   Set<MethodMetadata> beanMethods = retrieveBeanMethodMetadata(sourceClass);
   for (MethodMetadata methodMetadata : beanMethods) {
      configClass.addBeanMethod(new BeanMethod(methodMetadata, configClass));
   }
   // Process default methods on interfaces
   processInterfaces(configClass, sourceClass);
   // Process superclass, if any
   if (sourceClass.getMetadata().hasSuperClass()) {
      String superclass = sourceClass.getMetadata().getSuperClassName();
      if (superclass != null && !superclass.startsWith("java") &&
            !this.knownSuperclasses.containsKey(superclass)) {
         this.knownSuperclasses.put(superclass, configClass);
         // Superclass found, return its annotation metadata and recurse
         return sourceClass.getSuperClass();
      }
   }
   // No superclass -> processing is complete
   return null;
}
```

## enhanceConfigurationClasses

`postProcessBeanFactory` -> `enhanceConfigurationClasses` -> `ConfigurationClassEnhancer.enhance`

这里会对 `@Configuration` 使用 `CGLIB` 进行代理增强

```java
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
```

## ConfigurationClass

```java
/**
 * Represents a user-defined {@link Configuration @Configuration} class.
 * Includes a set of {@link Bean} methods, including all such methods
 * defined in the ancestry of the class, in a 'flattened-out' manner.
 */
final class ConfigurationClass {
}
```
