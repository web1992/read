# FAQ 002

**Spring 去 XML 化？**

可使用 `AnnotationConfigApplicationContext` 去调 Spring 中的 XML 配置

In much the same way that Spring XML files are used as input when instantiating a ClassPathXmlApplicationContext, @Configuration classes may be used as input when instantiating an AnnotationConfigApplicationContext. This allows for completely `XML-free`usage of the Spring container:

```java
public static void main(String[] args) {
    ApplicationContext ctx = new AnnotationConfigApplicationContext(AppConfig.class);
    MyService myService = ctx.getBean(MyService.class);
    myService.doStuff();
}
```

- [AnnotationConfigApplicationContext](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#beans-java-instantiating-container)
