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