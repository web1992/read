# 总结

- 1 Spring bom

> 更方便快捷的引入Spring的依赖（jar）[bom(Bill Of Materials)](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#overview-maven-bom)

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-framework-bom</artifactId>
            <version>4.3.12.RELEASE</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

- 2 Spring log

> [日志框架 use logback](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#overview-logging-slf4j)

```xml
<dependencies>
    <dependency>
        <groupId>org.slf4j</groupId>
        <artifactId>jcl-over-slf4j</artifactId>
        <version>1.7.21</version>
    </dependency>
    <dependency>
        <groupId>ch.qos.logback</groupId>
        <artifactId>logback-classic</artifactId>
        <version>1.1.7</version>
    </dependency>
</dependencies>
```

- 3 Spring 应用场景

[Usage scenarios](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#overview-usagescenarios)

![](./images/overview-full.png)