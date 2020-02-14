# mybatis tx

- [https://www.cnblogs.com/756623607-zhang/p/10291704.html](https://www.cnblogs.com/756623607-zhang/p/10291704.html)

## DataSourceTransactionManager

- [DataSourceTransactionManager](./images/DataSourceTransactionManager.png)

## Transaction

- `JdbcTransaction`
- `ManagedTransaction`
- `SpringManagedTransaction`

```java
// Transaction 接口的定义
public interface Transaction {

  /**
   * Retrieve inner database connection
   * @return DataBase connection
   * @throws SQLException
   */
  Connection getConnection() throws SQLException;

  /**
   * Commit inner database connection.
   * @throws SQLException
   */
  void commit() throws SQLException;

  /**
   * Rollback inner database connection.
   * @throws SQLException
   */
  void rollback() throws SQLException;

  /**
   * Close inner database connection.
   * @throws SQLException
   */
  void close() throws SQLException;

}
```

## TransactionFactory

- `ManagedTransactionFactory`
- `JdbcTransactionFactory`
- `SpringManagedTransactionFactory`

`SpringManagedTransactionFactory` 是在 `SpringManagedTransactionFactory` 中创建的

代码片段如下：

```java
// org.mybatis.spring.SqlSessionFactoryBean
protected SqlSessionFactory buildSqlSessionFactory() throws IOException {
    // 省略其他代码
    if (this.transactionFactory == null) {
      this.transactionFactory = new SpringManagedTransactionFactory();
    }
    // 创建 Environment
    Environment environment = new Environment(this.environment, this.transactionFactory, this.dataSource);
    configuration.setEnvironment(environment);
}
```

## SqlSessionUtils

`SqlSessionUtils` 是创建事务回调的 `SqlSessionSynchronization` 实现类的工具类

## SqlSessionSynchronization

```java
// org.mybatis.spring.SqlSessionUtils.SqlSessionSynchronization
// SqlSessionSynchronization 是 mybatis 中的事务回调
// 这里说下为什么需要这个回调：
// 我们使用了 Spring,事务已经交给了Srping 进行提交/回滚
// 但是MyBatis 实现了基于SqlSession 的缓存
// 当事务提交的时候，就需要清除这些缓存，这就是回调的作用
private static final class SqlSessionSynchronization extends TransactionSynchronizationAdapter {
    public void afterCompletion(int status) {
        holder.getSqlSession().commit();
        holder.getSqlSession().rollback();
    }
    public void beforeCommit(boolean readOnly) {
        this.holder.getSqlSession().flushStatements();
    }
}
```

## TransactionSynchronizationAdapter

`Spring` 事务管理的接口类(回调函数类)
