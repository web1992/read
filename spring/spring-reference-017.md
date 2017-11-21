# Transaction Management

- 01 [PlatformTransactionManager](#1-platformtransactionmanager)
- 02 [TransactionDefinition](#2-transactiondefinition )
- 03 [TransactionStatus](#3-transactionstatus)

## 1 PlatformTransactionManager

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#transaction-strategies)

```java
public interface PlatformTransactionManager {

    TransactionStatus getTransaction(TransactionDefinition definition) throws TransactionException;

    void commit(TransactionStatus status) throws TransactionException;

    void rollback(TransactionStatus status) throws TransactionException;
}
```

## 2 TransactionDefinition

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#transaction-strategies)

The TransactionDefinition interface specifies:

- Isolation: The degree to which this transaction is isolated from the work of other transactions. For example, can this transaction see uncommitted writes from other transactions?
- Propagation: Typically, all code executed within a transaction scope will run in that transaction. However, you have the option of specifying the behavior in the event that a transactional method is executed when a transaction context already exists. For example, code can continue running in the existing transaction (the common case); or the existing transaction can be suspended and a new transaction created. Spring offers all of the transaction propagation options familiar from EJB CMT. To read about the semantics of transaction propagation in Spring, see Section 17.5.7, “Transaction propagation”.
- Timeout: How long this transaction runs before timing out and being rolled back automatically by the underlying transaction infrastructure.
- Read-only status: A read-only transaction can be used when your code reads but does not modify data. Read-only transactions can be a useful optimization in some cases, such as when you are using Hibernate.

## 3 TransactionStatus

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#transaction-strategies)

```java
public interface TransactionStatus extends SavepointManager {

    boolean isNewTransaction();

    boolean hasSavepoint();

    void setRollbackOnly();

    boolean isRollbackOnly();

    void flush();

    boolean isCompleted();

}
```