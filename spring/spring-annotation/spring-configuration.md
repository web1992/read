# @Configuration

[ClassPathBeanDefinitionScanner 分析](.././spring-context/spring-class-path-bean-definition-scanner.md)

- [@Configuration](#configuration)
  - [Define of Configuration](#define-of-configuration)
  - [AnnotationConfigApplicationContext](#annotationconfigapplicationcontext)
  - [ConfigurationClassPostProcessor](#configurationclasspostprocessor)
    - [postProcessBeanDefinitionRegistry](#postprocessbeandefinitionregistry)
  - [ConfigurationClassParser](#configurationclassparser)
    - [doProcessConfigurationClass](#doprocessconfigurationclass)
  - [ConfigurationClass](#configurationclass)

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

## ConfigurationClassParser

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
