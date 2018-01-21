# Integration Testing

- 01 [Goals of Integration Testing](#01-goals-of-integration-testing)
- 02 [Context management and cachin](#02-context-management-and-cachin)
- 03 [Dependency Injection of test fixtures](#03-dependency-injection-of-test-fixtures)
- 04 [Transaction management](#04-transaction-management)
- 05 [Support classes for integration testing](#05-support-classes-for-integration-testing)
- 06 [JDBC Testing Support](#06-jdbc-testing-support)
- 07 [Annotations](#07-annotations)
- 08 [Spring Testing Annotations](#08-spring-testing-annotations)
- 09 [Standard Annotation Support](#09-standard-annotation-support)
- 10 [Spring JUnit 4 Testing Annotations](#10-spring-junit-4-testing-annotations)
- 11 [Meta-Annotation Support for Testing](#11-meta-annotation-support-for-testing)
- 12 [Key abstractions](#12-key-abstractions)

## 01 Goals of Integration Testing

Spring’s integration testing support has the following primary goals:

- To manage Spring IoC container caching between test execution.
- To provide Dependency Injection of test fixture instances.
- To provide transaction management appropriate to integration testing.
- To supply Spring-specific base classes that assist developers in writing integration tests.

The next few sections describe each goal and provide links to implementation and configuration details.

## 02 Context management and caching

See Section 15.5.4, [Context managemen](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#testcontext-ctx-management) and the section called [Context caching](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#testcontext-ctx-management-caching) with the TestContext framework.

## 03 Dependency Injection of test fixtures

## 04 Transaction management

## 05 Support classes for integration testing

- ApplicationContext

- JdbcTemplate

## 06 JDBC Testing Support

- JdbcTestUtils
- AbstractTransactionalJUnit4SpringContextTests
- AbstractTransactionalTestNGSpringContextTests

## 07 Annotations

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#integration-testing-annotations)

### 08 Spring Testing Annotations

@BootstrapWith

@ContextConfiguration

@ContextConfiguration defines class-level metadata that is used to determine how to load and configure an ApplicationContext for integration tests. Specifically, @ContextConfiguration declares the application context resource locations or the annotated classes that will be used to load the context.

Resource locations are typically XML configuration files or Groovy scripts located in the classpath; whereas, annotated classes are typically @Configuration classes. However, resource locations can also refer to files and scripts in the file system, and annotated classes can be component classes, etc.

```java
@ContextConfiguration("/test-config.xml")
public class XmlApplicationContextTests {
    // class body...
}
```

@WebAppConfiguration

@WebAppConfiguration is a class-level annotation that is used to declare that the ApplicationContext loaded for an integration test should be a WebApplicationContext. The mere presence of @WebAppConfiguration on a test class ensures that a WebApplicationContext will be loaded for the test, using the default value of "file:src/main/webapp" for the path to the root of the web application (i.e., the resource base path). The resource base path is used behind the scenes to create a MockServletContext which serves as the ServletContext for the test’s WebApplicationContext.

```java
@ContextConfiguration
@WebAppConfiguration("classpath:test-web-resources")
public class WebAppTests {
    // class body...
}
```

@ContextHierarchy

```java
@ContextHierarchy({
    @ContextConfiguration("/parent-config.xml"),
    @ContextConfiguration("/child-config.xml")
})
public class ContextHierarchyTests {
    // class body...
}
```

@ActiveProfiles

```java
@ContextConfiguration
@ActiveProfiles({"dev", "integration"})
public class DeveloperIntegrationTests {
    // class body...
}
```

@TestPropertySource

@TestPropertySource is a class-level annotation that is used to configure the locations of properties files and inlined properties to be added to the set of PropertySources in the Environment for an ApplicationContext loaded for an integration test.

The following example demonstrates how to declare a properties file from the classpath.

```java
@ContextConfiguration
@TestPropertySource("/test.properties")
public class MyIntegrationTests {
    // class body...
}
```

The following example demonstrates how to declare inlined properties.

```java
@ContextConfiguration
@TestPropertySource(properties = { "timezone = GMT", "port: 4242" })
public class MyIntegrationTests {
    // class body...
}
```

@DirtiesContext

@TestExecutionListeners

@Commit

@Commit indicates that the transaction for a transactional test method should be committed after the test method has completed. @Commit can be used as a direct replacement for @Rollback(false) in order to more explicitly convey the intent of the code. Analogous to @Rollback, @Commit may also be declared as a class-level or method-level annotation.

```java
@Commit
@Test
public void testProcessWithoutRollback() {
    // ...
}
```

@Rollback

@Rollback indicates whether the transaction for a transactional test method should be rolled back after the test method has completed. If true, the transaction is rolled back; otherwise, the transaction is committed (see also @Commit). Rollback semantics for integration tests in the Spring TestContext Framework default to true even if @Rollback is not explicitly declared.

When declared as a class-level annotation, @Rollback defines the default rollback semantics for all test methods within the test class hierarchy. When declared as a method-level annotation, @Rollback defines rollback semantics for the specific test method, potentially overriding class-level @Rollback or @Commit semantics.

```java
@Rollback(false)
@Test
public void testProcessWithoutRollback() {
    // ...
}
```

@BeforeTransaction

@AfterTransaction

@Sql

@SqlConfig

@SqlGroup

## 09 Standard Annotation Support

`@Autowired`
`@Qualifier`
`@Resource` (javax.annotation) if JSR-250 is present
`@ManagedBean` (javax.annotation) if JSR-250 is present
`@Inject` (javax.inject) if JSR-330 is present
`@Named` (javax.inject) if JSR-330 is present
`@PersistenceContext` (javax.persistence) if JPA is present
`@PersistenceUnit` (javax.persistence) if JPA is present
`@Required`

## 10 Spring JUnit 4 Testing Annotations

The following annotations are only supported when used in conjunction with the SpringRunner, Spring’s JUnit rules, or Spring’s JUnit 4 support classes.

spring and JUnit 4 特殊注解

@IfProfileValue

@ProfileValueSourceConfiguration

@Timed

制定在多少时间内完成测试

```java
@Timed(millis=1000)// (in milliseconds 毫秒)
public void testProcessWithOneSecondTimeout() {
    // some logic that should not take longer than 1 second to execute
}
```

@Repeat

重复执行10次

```java
@Repeat(10)
@Test
public void testProcessRepeatedly() {
    // ...
}
```

## 11 Meta-Annotation Support for Testing

- `@BootstrapWith`
- `@ContextConfiguration`
- `@ContextHierarchy`
- `@ActiveProfiles`
- `@TestPropertySource`
- `@DirtiesContext`
- `@WebAppConfiguration`
- `@TestExecutionListeners`
- `@Transactional`
- `@BeforeTransaction`
- `@AfterTransaction`
- `@Commit`
- `@Rollback`
- `@Sql`
- `@SqlConfig`
- `@SqlGroup`
- `@Repeat`
- `@Timed`
- `@IfProfileValue`
- `@ProfileValueSourceConfiguration`

> For example, if we discover that we are repeating the following configuration across our JUnit 4 based test suite…​

## 12 Key abstractions

TestContextManager
TestContext
TestExecutionListener
SmartContextLoader

## 13 Context management

Context configuration with XML resources
```java
@RunWith(SpringRunner.class)
// ApplicationContext will be loaded from "/app-config.xml" and
// "/test-config.xml" in the root of the classpath
@ContextConfiguration(locations={"/app-config.xml", "/test-config.xml"})
public class MyTest {
    // class body...
}
```

Context configuration with Groovy scripts

```java
@RunWith(SpringRunner.class)
// ApplicationContext will be loaded from "/AppConfig.groovy" and
// "/TestConfig.groovy" in the root of the classpath
@ContextConfiguration({"/AppConfig.groovy", "/TestConfig.Groovy"})
public class MyTest {
    // class body...
}
```

Context configuration with annotated classes

```java
@RunWith(SpringRunner.class)
// ApplicationContext will be loaded from AppConfig and TestConfig
@ContextConfiguration(classes = {AppConfig.class, TestConfig.class})
public class MyTest {
    // class body...
}
```

@Configuration

```java
@RunWith(SpringRunner.class)
// ApplicationContext will be loaded from the
// static nested Config class
@ContextConfiguration
public class OrderServiceTest {

    @Configuration
    static class Config {

        // this bean will be injected into the OrderServiceTest class
        @Bean
        public OrderService orderService() {
            OrderService orderService = new OrderServiceImpl();
            // set properties, etc.
            return orderService;
        }
    }

    @Autowired
    private OrderService orderService;

    @Test
    public void testOrderService() {
        // test the orderService
    }

}
```

## 14 Context configuration inheritance

## 15 Mixing XML, Groovy scripts, and annotated classes

If you want to use resource locations (e.g., XML or Groovy) and @Configuration classes to configure your tests, you will have to pick one as the entry point, and that one will have to include or import the other. For example, in XML or Groovy scripts you can include @Configuration classes via component scanning or define them as normal Spring beans; whereas, in a @Configuration class you can use @ImportResource to import XML configuration files or Groovy scripts. Note that this behavior is semantically equivalent to how you configure your application in production: in production configuration you will define either a set of XML or Groovy resource locations or a set of @Configuration classes that your production ApplicationContext will be loaded from, but you still have the freedom to include or import the other type of configuration.

## 16 Context configuration with context initializers

## 17 Context configuration inheritance

inheritLocations

inheritInitializers

```java
RunWith(SpringRunner.class)
// ApplicationContext will be loaded from "/base-config.xml"
// in the root of the classpath
@ContextConfiguration("/base-config.xml")
public class BaseTest {
    // class body...
}

// ApplicationContext will be loaded from "/base-config.xml" and
// "/extended-config.xml" in the root of the classpath
@ContextConfiguration("/extended-config.xml")
public class ExtendedTest extends BaseTest {
    // class body...
}
```

## 18 Context configuration with environment profiles

## 19 Loading a WebApplicationContext

This is interpreted as a path relative to the root of your JVM (i.e., normally the path to your project). If you’re familiar with the directory structure of a web application in a Maven project, you’ll know that "src/main/webapp" is the default location for the root of your WAR. If you need to override this default, simply provide an alternate path to the @WebAppConfiguration annotation (e.g., @WebAppConfiguration("src/test/webapp")). If you wish to reference a base resource path from the classpath instead of the file system, just use Spring’s classpath: prefix.

## 20 Context caching

缓存费时的`ApplicationContext`

>note

The Spring TestContext framework stores application contexts in a static cache. This means that the context is literally stored in a static variable. In other words, if tests execute in separate processes the static cache will be cleared between each test execution, and this will effectively disable the caching mechanism.

To benefit from the caching mechanism, all tests must run within the same process or test suite. This can be achieved by executing all tests as a group within an IDE. Similarly, when executing tests with a build framework such as Ant, Maven, or Gradle it is important to make sure that the build framework does not fork between tests. For example, if the forkMode for the Maven Surefire plug-in is set to always or pertest, the TestContext framework will not be able to cache application contexts between test classes and the build process will run significantly slower as a result.

## 21 Context hierarchies

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#testcontext-ctx-management-ctx-hierarchies)

When writing integration tests that rely on a loaded Spring ApplicationContext, it is often sufficient to test against a single context; however, there are times when it is beneficial or even necessary to test against a hierarchy of ApplicationContexts. For example, if you are developing a Spring MVC web application you will typically have a root WebApplicationContext loaded via Spring’s ContextLoaderListener and a child WebApplicationContext loaded via Spring’s DispatcherServlet. This results in a parent-child context hierarchy where shared components and infrastructure configuration are declared in the root context and consumed in the child context by web-specific components. Another use case can be found in Spring Batch applications where you often have a parent context that provides configuration for shared batch infrastructure and a child context for the configuration of a specific batch job.