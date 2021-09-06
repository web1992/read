# Spring Transaction

The following sections describe the Spring Framework’s transaction value-adds and technologies. (The chapter also includes discussions of best practices, application server integration, and solutions to common problems.)

- Advantages of the Spring Framework’s transaction support model describes why you would use the Spring Framework’s transaction abstraction instead of EJB Container-Managed Transactions (CMT) or choosing to drive local transactions through a proprietary API such as Hibernate.
  Understanding the Spring Framework transaction abstraction outlines the core classes and describes how to configure and obtain DataSource instances from a variety of sources.
- Synchronizing resources with transactionsdescribes how the application code ensures that resources are created, reused, and cleaned up properly.
- Declarative transaction management describes support for declarative transaction management.
- Programmatic transaction management covers support for programmatic (that is, explicitly coded) transaction management.
- Transaction bound event describes how you could use application events within a transaction.

## PlatformTransactionManager

```java
public interface PlatformTransactionManager {

	TransactionStatus getTransaction(TransactionDefinition definition) throws TransactionException;

	void commit(TransactionStatus status) throws TransactionException;

	void rollback(TransactionStatus status) throws TransactionException;
}
public abstract class TransactionException extends NestedRuntimeException {

}

public abstract class NestedRuntimeException extends RuntimeException {

}
```

## TransactionDefinition

## TransactionStatus

TransactionStatus is associated with a `thread of execution`.

## TransactionDefinition

## DataSourceUtils

```java
Connection conn = DataSourceUtils.getConnection(dataSource);
```

If an existing transaction already has a connection synchronized (linked) to it, that instance is returned. Otherwise, the method call triggers the creation of a new connection, which is (optionally) synchronized to any existing transaction, and made available for subsequent reuse in that same transaction. As mentioned, any SQLException is wrapped in a Spring Framework CannotGetJdbcConnectionException, one of the Spring Framework’s hierarchy of unchecked DataAccessExceptions. This approach gives you more information than can be obtained easily from the SQLException, and ensures portability across databases, even across different persistence technologies.

## TransactionAwareDataSourceProxy

## 17.5.1 Understanding the Spring Framework’s declarative transaction implementation

The most important concepts to grasp with regard to the Spring Framework’s declarative transaction support are that this support is enabled via AOP proxies, and that the transactional advice is driven by metadata (currently XML- or annotation-based). The combination of AOP with transactional metadata yields an AOP proxy that uses a TransactionInterceptor in conjunction with an appropriate PlatformTransactionManager implementation to drive transactions around method invocations.

## Table 17.2. Annotation driven transaction settings

`The default mode "proxy"` processes annotated beans to be proxied using Spring’s AOP framework (following proxy semantics, as discussed above, applying to method calls coming in through the proxy only). The alternative mode "aspectj" instead weaves the affected classes with Spring’s AspectJ transaction aspect, modifying the target class byte code to apply to any kind of method call. AspectJ weaving requires spring-aspects.jar in the classpath as well as load-time weaving (or compile-time weaving) enabled. (See the section called “Spring configuration” for details on how to set up load-time weaving.)

## @Transactional settings

The `@Transactional` annotation is metadata that specifies that an interface, class, or method must have transactional semantics; for example, "start a brand new read-only transaction when this method is invoked, suspending any existing transaction". The default @Transactional settings are as follows:

- Propagation setting is PROPAGATION_REQUIRED.
- Isolation level is ISOLATION_DEFAULT.
- Transaction is read/write.
- Transaction timeout defaults to the default timeout of the underlying transaction system, or to none if timeouts are not supported.
- Any RuntimeException triggers rollback, and any checked Exception does not.

## Transaction propagation

In Spring-managed transactions, be aware of the difference between physical and logical transactions, and how the propagation setting applies to this difference.

- PROPAGATION_REQUIRED

When the propagation setting is `PROPAGATION_REQUIRED`, a logical transaction scope is created for each method upon which the setting is applied. Each such logical transaction scope can determine rollback-only status individually, with an outer transaction scope being logically independent from the inner transaction scope. Of course, in case of standard `PROPAGATION_REQUIRED` behavior, all these scopes will be mapped to the same physical transaction. So a rollback-only marker set in the inner transaction scope does affect the outer transaction’s chance to actually commit (as you would expect it to).

- PROPAGATION_REQUIRES_NEW

`PROPAGATION_REQUIRES_NEW`, in contrast to `PROPAGATION_REQUIRED`, always uses `an independent physical transaction` for each affected transaction scope, never participating in an existing transaction for an outer scope. In such an arrangement, the underlying resource transactions are different and hence can commit or roll back independently, with an outer transaction not affected by an inner transaction’s rollback status, and with an inner transaction’s locks released immediately after its completion. Such an independent inner transaction may also declare its own isolation level, timeout and read-only settings, never inheriting an outer transaction’s characteristics.

- Nested

`PROPAGATION_NESTED` uses `a single physical transaction` with `multiple savepoints` that it can roll back to. Such partial rollbacks allow an inner transaction scope to trigger a rollback for its scope, with the outer transaction being able to continue the physical transaction despite some operations having been rolled back. This setting is typically mapped onto JDBC savepoints, so will only work with JDBC resource transactions. See Spring’s DataSourceTransactionManager.

## AnnotationTransactionAspect

使用 Aspect 编织事物

## TransactionTemplate

## Links

- [17. Transaction Management](https://docs.spring.io/spring-framework/docs/4.3.x/spring-framework-reference/htmlsingle/#transaction)
- [Transaction propagation](https://docs.spring.io/spring-framework/docs/4.3.x/spring-framework-reference/htmlsingle/#tx-propagation)
- [7.5.1 Understanding the Spring Framework’s declarative transaction implementation](https://docs.spring.io/spring-framework/docs/4.3.x/spring-framework-reference/htmlsingle/#tx-decl-explained)
