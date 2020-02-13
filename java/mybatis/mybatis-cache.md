# mybatis cache

## CachingExecutor

## init

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
    if (cacheEnabled) {
      executor = new CachingExecutor(executor);
    }
    executor = (Executor) interceptorChain.pluginAll(executor);
    return executor;
}
```

## createCacheKey

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

## CacheKey

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

## PerpetualCache

> 永久的缓存

## 参考

> mybatis 缓存

- [https://www.cnblogs.com/jtlgb/p/6037945.html](https://www.cnblogs.com/jtlgb/p/6037945.html)
- [https://tech.meituan.com/2018/01/19/mybatis-cache.html](https://tech.meituan.com/2018/01/19/mybatis-cache.html)
