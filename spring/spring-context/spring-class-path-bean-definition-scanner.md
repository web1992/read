# ClassPathBeanDefinitionScanner

`org.springframework.context.annotation.ClassPathBeanDefinitionScanner` 作用是扫描注册 `classpath` 下面的 `bean` (就是加载 `class` 对象，创建 `BeanDefinition` 对象)

可以参考 `mybatis` [org.mybatis.spring.mapper.ClassPathMapperScanner](../java/../../java/mybatis/mybatis-mapper-factory-bean.md) 的实现，看懂了这个，就明白了这个类的作用

## 概要

`ClassPathBeanDefinitionScanner` 用来扫描 `classpath` 路径下面的 bean

有下面的注解的类，都被扫描并注册成 `BeanDefinition`

- org.springframework.stereotype.Component
- org.springframework.stereotype.Repository
- org.springframework.stereotype.Service
- org.springframework.stereotype.Controller

## AnnotatedBeanDefinitionReader
