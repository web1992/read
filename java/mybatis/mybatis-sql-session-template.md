# SqlSessionTemplate

- [SqlSessionTemplate](#sqlsessiontemplate)
  - [SqlSessionTemplate 的创建](#sqlsessiontemplate-%e7%9a%84%e5%88%9b%e5%bb%ba)
  - [SqlSessionTemplate 中的核心方法](#sqlsessiontemplate-%e4%b8%ad%e7%9a%84%e6%a0%b8%e5%bf%83%e6%96%b9%e6%b3%95)
  - [SqlSessionTemplate UnsupportedOperationException](#sqlsessiontemplate-unsupportedoperationexception)
  - [SqlSessionInterceptor 代理](#sqlsessioninterceptor-%e4%bb%a3%e7%90%86)
  - [SqlSessionUtils](#sqlsessionutils)
    - [getSqlSession](#getsqlsession)
    - [closeSqlSession](#closesqlsession)
    - [SqlSessionSynchronization](#sqlsessionsynchronization)
  - [Reference](#reference)

`SqlSessionTemplate` 能与 `Spring` 事务的相结合，除了事务之外的请求还是给到了 `DefaultSqlSession`

我们在使用 Spring + Mbyatis 的时候，事务都交给了 Spring 进行管理，后面的 [SqlSessionTemplate UnsupportedOperationException](#sqlsessiontemplate-unsupportedoperationexception) 会简单说明

SqlSessionTemplate 可以看做是：`SqlSessionTemplate` = `DefaultSqlSession` + `Spring 事务`

`SqlSession` 接口的实现类有三个(`SqlSession` 中的方法可以参考 [SqlSession](./mybatis-sql-session.md))

- org.mybatis.spring.SqlSessionTemplate
- org.apache.ibatis.session.defaults.DefaultSqlSession
- org.apache.ibatis.session.SqlSessionManager

从上面的包的路径可以看出 `SqlSessionTemplate` 是 mybatis-spring 模块中与 Spring 集成的实现

`DefaultSqlSession` 和 `SqlSessionManager` 是 mybatis 的自己实现类

而我们使用最常使用的也就是 `SqlSessionTemplate`，也是核心实现

## SqlSessionTemplate 的创建

`SqlSessionTemplate` 的创建 是在 `SqlSessionDaoSupport` `中，SqlSessionDaoSupport` 是一个抽象类

`mybatis-spring` 中 `MapperFactoryBean` 继承了 `SqlSessionDaoSupport` 因此在初始化 `MapperFactoryBean` 的时候

就会调用 `setSqlSessionFactory` 方法进行 `SqlSessionTemplate` 的创建

```java
// MapperFactoryBean
public class MapperFactoryBean<T> extends SqlSessionDaoSupport implements FactoryBean<T> {

}

// SqlSessionDaoSupport 的 setSqlSessionFactory 方法
// setSqlSessionFactory 方法会在 Spring 进行依赖注入的时候被调用
public void setSqlSessionFactory(SqlSessionFactory sqlSessionFactory) {
  if (!this.externalSqlSession) {
    // 这里的 SqlSessionTemplate 是通过new 创建，并不是Spring 容器管理的
    // 通过 getBean 方法是获取不到这个 SqlSessionTemplate 对象的
    this.sqlSession = new SqlSessionTemplate(sqlSessionFactory);
  }
}
// 下面的 externalSqlSession 字段用来判断是否已经注入了 SqlSessionTemplate
// 如果注入了，externalSqlSession = true 上面的 setSqlSessionFactory 方法执行了，但是不回覆盖
// 已经创建的 SqlSessionTemplate
public void setSqlSessionTemplate(SqlSessionTemplate sqlSessionTemplate) {
  this.sqlSession = sqlSessionTemplate;
  this.externalSqlSession = true;
}
```

这里也许会有疑问，写了 `setSqlSessionFactory` 这个方法就能注入 `SqlSessionFactory` 对象？

事实上确实是这样的，这些注入都是由 `Spring` 完成了，对开发者无感知。（前提是这个类被注册成 BeanDefinition）

简单来说，就是在进行 Bean 初始化的时候，解析这个类的方法属性和父类的方法属性，并找到 set 开头的方法，进行依赖注入（而这里的 setSqlSessionFactory 是通过 `RootBeanDefinition.AUTOWIRE_BY_TYPE` 注入的,相关代码可以在 `AbstractAutowireCapableBeanFactory.populateBean` 找到）

当然也可以在 `xml` 配置中配置 `SqlSessionTemplate`,配置如下：

```xml
<!-- 如果配置了 SqlSessionTemplate 那么 setSqlSessionFactory new 的 SqlSessionTemplate 会被配置的覆盖 -->
<bean id="sqlSessionTemplate" class="org.mybatis.spring.SqlSessionTemplate">
    <constructor-arg ref="sqlSessionFactory" />
</bean>
```

## SqlSessionTemplate 中的核心方法

```java
// 构造方法
// 创建代理类 sqlSessionProxy
public SqlSessionTemplate(SqlSessionFactory sqlSessionFactory, ExecutorType executorType,
    PersistenceExceptionTranslator exceptionTranslator) {
  notNull(sqlSessionFactory, "Property 'sqlSessionFactory' is required");
  notNull(executorType, "Property 'executorType' is required");
  this.sqlSessionFactory = sqlSessionFactory;
  this.executorType = executorType;
  this.exceptionTranslator = exceptionTranslator;
  // 创建代理 Proxy.newProxyInstance
  this.sqlSessionProxy = (SqlSession) newProxyInstance(
      SqlSessionFactory.class.getClassLoader(),
      new Class[] { SqlSession.class },
      new SqlSessionInterceptor());
}
```

## SqlSessionTemplate UnsupportedOperationException

`SqlSessionTemplate` 中那些抛出 `UnsupportedOperationException` 异常的方法

```java
// 下面的这些方法如果直接调用就会出错
// 那么为什么要这样做呢？
// 是因为下面的 commit 和 rollback 是和事务相关的方法
// 当你使用了 SqlSessionTemplate 意味着你已经把事务管理权交给了 Spring 容器
// Spring 容器 来决定何时执行 commit 和 rollback
// 因此下面的方法不能让你来调用
public class SqlSessionTemplate implements SqlSession {
public void commit() {
  throw new UnsupportedOperationException("Manual commit is not allowed over a Spring managed SqlSession");
}

public void commit(boolean force) {
  throw new UnsupportedOperationException("Manual commit is not allowed over a Spring managed SqlSession");
}

public void rollback() {
  throw new UnsupportedOperationException("Manual rollback is not allowed over a Spring managed SqlSession");
}

public void rollback(boolean force) {
  throw new UnsupportedOperationException("Manual rollback is not allowed over a Spring managed SqlSession");
}

public void close() {
  throw new UnsupportedOperationException("Manual close is not allowed over a Spring managed SqlSession");
}
}
```

和事务无关的方法则是给 `sqlSessionProxy` 代理进行调用

```java
// 下面的查询方法交给 sqlSessionProxy
// sqlSessionProxy -> DefaultSqlSessionFactory -> DefaultSqlSession
// 代理类的相关代码在 SqlSessionInterceptor 中
public <T> T selectOne(String statement, Object parameter) {
  return this.sqlSessionProxy.<T> selectOne(statement, parameter);
}
```

## SqlSessionInterceptor 代理

下面的注释写的也很清楚，就是把 `MyBatis` 中的方法调用路由到从 `Spring` 事务管理器 (Spring's Transaction Manager)中获取的 `SqlSession` 对象中去

```java
/**
 * Proxy needed to route MyBatis method calls to the proper SqlSession got
 * from Spring's Transaction Manager
 * It also unwraps exceptions thrown by {@code Method#invoke(Object, Object...)} to
 * pass a {@code PersistenceException} to the {@code PersistenceExceptionTranslator}.
 */
private class SqlSessionInterceptor implements InvocationHandler {
  public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    // getSqlSession 获取 sqlSession 对象
    // SqlSessionUtils.getSqlSession -> org.springframework.transaction.support.TransactionSynchronizationManager.getResource
    // TransactionSynchronizationManager 从包路径可知道这个是Spring中的类
    final SqlSession sqlSession = getSqlSession(
        SqlSessionTemplate.this.sqlSessionFactory,
        SqlSessionTemplate.this.executorType,
        SqlSessionTemplate.this.exceptionTranslator);
    try {
      Object result = method.invoke(sqlSession, args);
      if (!isSqlSessionTransactional(sqlSession, SqlSessionTemplate.this.sqlSessionFactory)) {
        // force commit even on non-dirty sessions because some databases require
        // a commit/rollback before calling close()
        sqlSession.commit(true);
      }
      return result;
    } catch (Throwable t) {
      Throwable unwrapped = unwrapThrowable(t);
      if (SqlSessionTemplate.this.exceptionTranslator != null && unwrapped instanceof PersistenceException) {
        Throwable translated = SqlSessionTemplate.this.exceptionTranslator.translateExceptionIfPossible((PersistenceException) unwrapped);
        if (translated != null) {
          unwrapped = translated;
        }
      }
      throw unwrapped;
    } finally {
      closeSqlSession(sqlSession, SqlSessionTemplate.this.sqlSessionFactory);
    }
  }
}
```

## SqlSessionUtils

`SqlSessionUtils` 工具类是 `mybatis` 与 `Spring` 中 `org.springframework.transaction.support.TransactionSynchronizationManager` 类的桥梁

### getSqlSession

```java
/**
 * Gets an SqlSession from Spring Transaction Manager or creates a new one if needed.
 * Tries to get a SqlSession out of current transaction. If there is not any, it creates a new one.
 * Then, it synchronizes the SqlSession with the transaction if Spring TX is active and
 * <code>SpringManagedTransactionFactory</code> is configured as a transaction manager.
 *
 * @param sessionFactory a MyBatis {@code SqlSessionFactory} to create new sessions
 * @param executorType The executor type of the SqlSession to create
 * @param exceptionTranslator Optional. Translates SqlSession.commit() exceptions to Spring exceptions.
 * @throws TransientDataAccessResourceException if a transaction is active and the
 *             {@code SqlSessionFactory} is not using a {@code SpringManagedTransactionFactory}
 * @see SpringManagedTransactionFactory
 */
// SqlSessionUtils
public static SqlSession getSqlSession(SqlSessionFactory sessionFactory, ExecutorType executorType, PersistenceExceptionTranslator exceptionTranslator) {
  notNull(sessionFactory, "No SqlSessionFactory specified");
  notNull(executorType, "No ExecutorType specified");
  // 从 TransactionSynchronizationManager 中查询是否已经有
  SqlSessionHolder holder = (SqlSessionHolder) getResource(sessionFactory);
  if (holder != null && holder.isSynchronizedWithTransaction()) {
    if (holder.getExecutorType() != executorType) {
      throw new TransientDataAccessResourceException("Cannot change the ExecutorType when there is an existing transaction");
    }
    // 计数器+1
    holder.requested();
    if (logger.isDebugEnabled()) {
      logger.debug("Fetched SqlSession [" + holder.getSqlSession() + "] from current transaction");
    }
    // 返回 SqlSession
    return holder.getSqlSession();
  }
  if (logger.isDebugEnabled()) {
    logger.debug("Creating a new SqlSession");
  }
  // 不存在，则通过 sessionFactory 创建新的 SqlSession
  SqlSession session = sessionFactory.openSession(executorType);
  // Register session holder if synchronization is active (i.e. a Spring TX is active)
  //
  // Note: The DataSource used by the Environment should be synchronized with the
  // transaction either through DataSourceTxMgr or another tx synchronization.
  // Further assume that if an exception is thrown, whatever started the transaction will
  // handle closing / rolling back the Connection associated with the SqlSession.
  if (isSynchronizationActive()) {// 当前线程有事务存在
    Environment environment = sessionFactory.getConfiguration().getEnvironment();
    if (environment.getTransactionFactory() instanceof SpringManagedTransactionFactory) {
      if (logger.isDebugEnabled()) {
        logger.debug("Registering transaction synchronization for SqlSession [" + session + "]");
      }
      holder = new SqlSessionHolder(session, executorType, exceptionTranslator);
      bindResource(sessionFactory, holder);
      registerSynchronization(new SqlSessionSynchronization(holder, sessionFactory));
      holder.setSynchronizedWithTransaction(true);
      holder.requested();
    } else {
      if (getResource(environment.getDataSource()) == null) {
        if (logger.isDebugEnabled()) {
          logger.debug("SqlSession [" + session + "] was not registered for synchronization because DataSource is not transactional");
        }
      } else {
        throw new TransientDataAccessResourceException(
            "SqlSessionFactory must be using a SpringManagedTransactionFactory in order to use Spring transaction synchronization");
      }
    }
  } else {
    if (logger.isDebugEnabled()) {
      logger.debug("SqlSession [" + session + "] was not registered for synchronization because synchronization is not active");
    }
  }
  return session;
}

```

### closeSqlSession

```java
/**
 * Checks if {@code SqlSession} passed as an argument is managed by Spring {@code TransactionSynchronizationManager}
 * If it is not, it closes it, otherwise it just updates the reference counter and
 * lets Spring call the close callback when the managed transaction ends
 *
 * @param session
 * @param sessionFactory
 */
public static void closeSqlSession(SqlSession session, SqlSessionFactory sessionFactory) {
  notNull(session, "No SqlSession specified");
  notNull(sessionFactory, "No SqlSessionFactory specified");
  SqlSessionHolder holder = (SqlSessionHolder) getResource(sessionFactory);
  if ((holder != null) && (holder.getSqlSession() == session)) {
    if (logger.isDebugEnabled()) {
      logger.debug("Releasing transactional SqlSession [" + session + "]");
    }
    holder.released();
  } else {
    if (logger.isDebugEnabled()) {
      logger.debug("Closing non transactional SqlSession [" + session + "]");
    }
    session.close();
  }
}
```

### SqlSessionSynchronization

```java
/**
 * Callback for cleaning up resources. It cleans TransactionSynchronizationManager and
 * also commits and closes the {@code SqlSession}.
 * It assumes that {@code Connection} life cycle will be managed by
 * {@code DataSourceTransactionManager} or {@code JtaTransactionManager}
 */
private static final class SqlSessionSynchronization extends TransactionSynchronizationAdapter {
    // ...
}
```

## Reference

- [SqlSessionFactoryBean](./mybatis-sql-session-factory-bean.md)
