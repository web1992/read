# mybatis cache

## CachingExecutor

## createCacheKey

```java
public CacheKey createCacheKey(MappedStatement ms, Object parameterObject, RowBoundsrowBounds, BoundSql boundSql) {
  if (closed) throw new ExecutorException("Executor was closed.");
  CacheKey cacheKey = new CacheKey();
  cacheKey.update(ms.getId());
  cacheKey.update(rowBounds.getOffset());
  cacheKey.update(rowBounds.getLimit());
  cacheKey.update(boundSql.getSql());
  List<ParameterMapping> parameterMappings = boundSql.getParameterMappings();
  if (parameterMappings.size() > 0 && parameterObject != null) {
    TypeHandlerRegistry typeHandlerRegistry = ms.getConfiguration().getTypeHandlerRegistry();
    if (typeHandlerRegistry.hasTypeHandler(parameterObject.getClass())) {
      cacheKey.update(parameterObject);
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
  return cacheKey;
}
```

## CacheKey

> mybatis 缓存

- [https://www.cnblogs.com/jtlgb/p/6037945.html](https://www.cnblogs.com/jtlgb/p/6037945.html)
