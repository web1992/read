# Integration Testing

## Goals of Integration Testing

Spring’s integration testing support has the following primary goals:

- To manage Spring IoC container caching between test execution.
- To provide Dependency Injection of test fixture instances.
- To provide transaction management appropriate to integration testing.
- To supply Spring-specific base classes that assist developers in writing integration tests.

The next few sections describe each goal and provide links to implementation and configuration details.

## Context management and caching

See Section 15.5.4, [Context managemen](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#testcontext-ctx-management) and the section called [Context caching](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#testcontext-ctx-management-caching) with the TestContext framework.

## Dependency Injection of test fixtures

## Transaction management

## Support classes for integration testing

- ApplicationContext

- JdbcTemplate

## JDBC Testing Support

- JdbcTestUtils
- AbstractTransactionalJUnit4SpringContextTests
- AbstractTransactionalTestNGSpringContextTests

## Annotations

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#integration-testing-annotations)

### Spring Testing Annotations

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

## Standard Annotation Support

`@Autowired`
`@Qualifier`
`@Resource` (javax.annotation) if JSR-250 is present
`@ManagedBean` (javax.annotation) if JSR-250 is present
`@Inject` (javax.inject) if JSR-330 is present
`@Named` (javax.inject) if JSR-330 is present
`@PersistenceContext` (javax.persistence) if JPA is present
`@PersistenceUnit` (javax.persistence) if JPA is present
`@Required`

## Spring JUnit 4 Testing Annotations

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

## Meta-Annotation Support for Testing

`@BootstrapWith`
`@ContextConfiguration`
`@ContextHierarchy`
`@ActiveProfiles`
`@TestPropertySource`
`@DirtiesContext`
`@WebAppConfiguration`
`@TestExecutionListeners`
`@Transactional`
`@BeforeTransaction`
`@AfterTransaction`
`@Commit`
`@Rollback`
`@Sql`
`@SqlConfig`
`@SqlGroup`
`@Repeat`
`@Timed`
`@IfProfileValue`
`@ProfileValueSourceConfiguration`

> For example, if we discover that we are repeating the following configuration across our JUnit 4 based test suite…​

## Key abstractions