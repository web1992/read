# StatementHandler

- BaseStatementHandler
- CallableStatementHandler
- PreparedStatementHandler
- RoutingStatementHandler
- SimpleStatementHandler

## RoutingStatementHandler

```java
// RoutingStatementHandler
public RoutingStatementHandler(Executor executor, MappedStatement ms, Object parameter, RowBounds rowBounds,ResultHandler resultHandler, BoundSql boundSql) {
  switch (ms.getStatementType()) {
    case STATEMENT:
      delegate = new SimpleStatementHandler(executor, ms, parameter, rowBounds, resultHandler, boundSql);
      break;
    case PREPARED:
      delegate = new PreparedStatementHandler(executor, ms, parameter, rowBounds, resultHandler, boundSql);
      break;
    case CALLABLE:
      delegate = new CallableStatementHandler(executor, ms, parameter, rowBounds, resultHandler, boundSql);
      break;
    default:
      throw new ExecutorException("Unknown statement type: " + ms.getStatementType());
  }
}
```