# Object Relational Mapping (ORM) Data Access

## Introduction to ORM with Spring

## General ORM integration considerations

This section highlights considerations that apply to all ORM technologies. The Section 20.3, [“Hibernate”](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#orm-hibernate) section provides more details and also show these features and configurations in a concrete context.

The major goal of Spring’s ORM integration is clear application layering, with any data access and transaction technology, and for loose coupling of application objects. No more business service dependencies on the data access or transaction strategy, no more hard-coded resource lookups, no more hard-to-replace singletons, no more custom service registries. One simple and consistent approach to wiring up application objects, keeping them as reusable and free from container dependencies as possible. All the individual data access features are usable on their own but integrate nicely with Spring’s application context concept, providing XML-based configuration and cross-referencing of plain JavaBean instances that need not be Spring-aware. In a typical Spring application, many important objects are JavaBeans: data access templates, data access objects, transaction managers, business services that use the data access objects and transaction managers, web view resolvers, web controllers that use the business services,and so on.

## Resource and transaction management

## Exception translation

## Hibernate

- 20.3.1. SessionFactory setup in a Spring container
- 20.3.2. Implementing DAOs based on plain Hibernate API
- 20.3.3. Declarative transaction demarcation
- 20.3.4. Programmatic transaction demarcation
- 20.3.5. Transaction management strategies
- 20.3.6. Comparing container-managed and locally defined resources
- 20.3.7. Spurious application server warnings with Hibernate

## JDO

- 20.4.1. PersistenceManagerFactory setup
- 20.4.2. Implementing DAOs based on the plain JDO API
- 20.4.3. Transaction management
- 20.4.4. JdoDialect

## JPA

