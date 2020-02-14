# mybatis cache

- [mybatis cache](#mybatis-cache)
  - [本地缓存](#%e6%9c%ac%e5%9c%b0%e7%bc%93%e5%ad%98)
    - [BaseExecutor](#baseexecutor)
  - [二级缓存](#%e4%ba%8c%e7%ba%a7%e7%bc%93%e5%ad%98)
    - [CachingExecutor init](#cachingexecutor-init)
    - [createCacheKey](#createcachekey)
    - [CacheKey](#cachekey)
  - [Cache](#cache)
  - [参考](#%e5%8f%82%e8%80%83)

`mybatis` 缓存有两种：基于 Session 的本地缓存和二级缓存

下面的来自 `Mybatis` 官网中文文档：

本地缓存

Mybatis 使用到了两种缓存：本地缓存（local cache）和二级缓存（second level cache）。

每当一个新 session 被创建，MyBatis 就会创建一个与之相关联的本地缓存。任何在 session 执行过的查询语句本身都会被保存在本地缓存中，那么，相同的查询语句和相同的参数所产生的更改就不会二度影响数据库了。本地缓存会被增删改、提交事务、关闭事务以及关闭 session 所清空。

默认情况下，本地缓存数据可在整个 session 的周期内使用，这一缓存需要被用来解决循环引用错误和加快重复嵌套查询的速度，所以它可以不被禁用掉，但是你可以设置 localCacheScope=STATEMENT 表示缓存仅在语句执行时有效。

注意，如果 localCacheScope 被设置为 SESSION，那么 MyBatis 所返回的引用将传递给保存在本地缓存里的相同对象。对返回的对象（例如 list）做出任何更新将会影响本地缓存的内容，进而影响存活在 session 生命周期中的缓存所返回的值。因此，不要对 MyBatis 所返回的对象作出更改，以防后患。

## 本地缓存

本地缓存(很多人都喜欢成为一级缓存)，这里说下为什么一级缓存是基于 `Session` 的: _因为 `SqlSession` 中的缓存是基于 `Executor`(`BaseExecutor`) 实现的_

看下 `DefaultSqlSession` 的代码片段

```java
// Executor 是 DefaultSqlSession 的成员变量
// 每一个 SqlSession 对象就有一个 Executor 对象
// 因此不同的 SqlSession 对象缓存的内容是内部的，外部无法感知到
public class DefaultSqlSession implements SqlSession {
  private Configuration configuration;
  private Executor executor;
  // 省略其他代码
}
```

### BaseExecutor

本地缓存是基于 `BaseExecutor` 实现的,看下下面的代码片段

```java
// BaseExecutor
public abstract class BaseExecutor implements Executor {
  // 本地缓存
  protected PerpetualCache localCache;
}
```

## 二级缓存

二级缓存是基于 `CachingExecutor` 实现的

### CachingExecutor init

```java
// org.apache.ibatis.session.Configuration
// Executor 是通过 Configuration 的 newExecutor 方法创建的
// 根据 executorType 来创建 executor
// 如果没有禁用 cache 那么就用 CachingExecutor 对 executor 进行包装
// 让它拥有 Cache 的能力
public Executor newExecutor(Transaction transaction, ExecutorType executorType) {
    executorType = executorType == null ? defaultExecutorType : executorType;
    executorType = executorType == null ? ExecutorType.SIMPLE : executorType;
    Executor executor;
    if (ExecutorType.BATCH == executorType) {
      executor = new BatchExecutor(this, transaction);
    } else if (ExecutorType.REUSE == executorType) {
      executor = new ReuseExecutor(this, transaction);
    } else {
      executor = new SimpleExecutor(this, transaction);
    }
    // 如果打开了，进行包装
    if (cacheEnabled) {
      executor = new CachingExecutor(executor);
    }
    executor = (Executor) interceptorChain.pluginAll(executor);
    return executor;
}
```

### createCacheKey

```java
// BaseExecutor
// 创建 cacheKey
public CacheKey createCacheKey(MappedStatement ms, Object parameterObject, RowBoundsrowBounds, BoundSql boundSql) {
  if (closed) throw new ExecutorException("Executor was closed.");
  CacheKey cacheKey = new CacheKey();
  cacheKey.update(ms.getId());// cn.web1992.mybatiss.dal.dao.UserDao.get
  cacheKey.update(rowBounds.getOffset());// 0
  cacheKey.update(rowBounds.getLimit());// 2147483647
  cacheKey.update(boundSql.getSql());// select * from t_user where id =?;
  List<ParameterMapping> parameterMappings = boundSql.getParameterMappings();
  if (parameterMappings.size() > 0 && parameterObject != null) {
    TypeHandlerRegistry typeHandlerRegistry = ms.getConfiguration().getTypeHandlerRegistry();
    if (typeHandlerRegistry.hasTypeHandler(parameterObject.getClass())) {
      cacheKey.update(parameterObject);// u1 参数类型
    } else {
      MetaObject metaObject = configuration.newMetaObject(parameterObject);
      for (ParameterMapping parameterMapping : parameterMappings) {
        String propertyName = parameterMapping.getProperty();
        if (metaObject.hasGetter(propertyName)) {
          cacheKey.update(metaObject.getValue(propertyName));
        } else if (boundSql.hasAdditionalParameter(propertyName)) {
          cacheKey.update(boundSql.getAdditionalParameter(propertyName));
        }
      }
    }
  }
  // hashcode:checksum
  // 2129916964:4215941848:cn.web1992.mybatiss.dal.dao.UserDao.get:0:2147483647:select * from t_user where id =?;:u1
  return cacheKey;
}
```

### CacheKey

`CacheKey` 主要的方法就是 `update` 和 `equals`

`update` 负责把所以的对象都添加到 的 `updateList` 中 而 `equals` 则负责 `updateList` 中的所有的对象的对比

```java
// update
// 每次 update 的时候会更新 checksum 和 hashcode
public void update(Object object) {
  int baseHashCode = object == null ? 1 : object.hashCode();
  count++;
  checksum += baseHashCode;
  baseHashCode *= count;
  hashcode = multiplier * hashcode + baseHashCode;
  updateList.add(object);
}
// 对比
public boolean equals(Object object) {
  if (this == object) return true;
  if (!(object instanceof CacheKey)) return false;
  final CacheKey cacheKey = (CacheKey) object;
  if (hashcode != cacheKey.hashcode) return false;
  if (checksum != cacheKey.checksum) return false;
  if (count != cacheKey.count) return false;
  for (int i = 0; i < updateList.size(); i++) {
    Object thisObject = updateList.get(i);
    Object thatObject = cacheKey.updateList.get(i);
    if (thisObject == null) {
      if (thatObject != null) return false;
    } else {
      if (!thisObject.equals(thatObject)) return false;
    }
  }
  return true;
}
// toString
public String toString() {
    StringBuilder returnValue = new StringBuilder().append(hashcode).append(':').append(checksum);
    for (int i = 0; i < updateList.size(); i++) {
      returnValue.append(':').append(updateList.get(i));
    }

    return returnValue.toString();
}
```

## Cache

- FifoCache
- LoggingCache
- LruCache
- ScheduledCache
- SerializedCache
- SoftCache
- SynchronizedCache
- TransactionalCache
- WeakCache
- PerpetualCache

## 参考

> mybatis 缓存

- [https://www.cnblogs.com/jtlgb/p/6037945.html](https://www.cnblogs.com/jtlgb/p/6037945.html)
- [https://tech.meituan.com/2018/01/19/mybatis-cache.html](https://tech.meituan.com/2018/01/19/mybatis-cache.html)
- [https://www.cnblogs.com/756623607-zhang/p/10291704.html](https://www.cnblogs.com/756623607-zhang/p/10291704.html)
