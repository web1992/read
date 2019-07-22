# MapperScannerConfigurer

## MapperScannerConfigurer

```java
public class MapperScannerConfigurer implements BeanDefinitionRegistryPostProcessor, InitializingBean, ApplicationContextAware, BeanNameAware {
// ...
}
```

| spring interface                    | desc                              |
| ----------------------------------- | --------------------------------- |
| BeanDefinitionRegistryPostProcessor | postProcessBeanDefinitionRegistry |
| InitializingBean                    | 检查 bean properties              |
| ApplicationContextAware             | setApplicationContext             |
| BeanNameAware                       | setBeanName                       |

`postProcessBeanDefinitionRegistry` 是最重要的方法，用来注册 `bean`

```java
public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException {
  if (this.processPropertyPlaceHolders) {
    processPropertyPlaceHolders();
  }
  ClassPathMapperScanner scanner = new ClassPathMapperScanner(registry);
  scanner.setAddToConfig(this.addToConfig);
  scanner.setAnnotationClass(this.annotationClass);
  scanner.setMarkerInterface(this.markerInterface);
  scanner.setSqlSessionFactory(this.sqlSessionFactory);
  scanner.setSqlSessionTemplate(this.sqlSessionTemplate);
  scanner.setSqlSessionFactoryBeanName(this.sqlSessionFactoryBeanName);
  scanner.setSqlSessionTemplateBeanName(this.sqlSessionTemplateBeanName);
  scanner.setResourceLoader(this.applicationContext);
  scanner.setBeanNameGenerator(this.nameGenerator);
  scanner.registerFilters();
  scanner.scan(StringUtils.tokenizeToStringArray(this.basePackage, ConfigurableApplicationContext.CONFIG_LOCATION_DELIMITERS));
}
```

## basePackage

`basePackage` 参数

`annotationClass` 和 `markerInterface` 来控制 `basePackage` 那些类需要被当做 `mapper`

如果都为空，那么 `basePackage` 下面所以的 `interface` 都被当做 `mapper`

## ClassPathMapperScanner
