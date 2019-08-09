# Plugin

## Plugin class

```java
public class Plugin implements InvocationHandler {

  private Object target;
  private Interceptor interceptor;
  private Map<Class<?>, Set<Method>> signatureMap;

  private Plugin(Object target, Interceptor interceptor, Map<Class<?>, Set<Method>> signatureMap) {
    this.target = target;
    this.interceptor = interceptor;
    this.signatureMap = signatureMap;
  }
  // 生成代理
  public static Object wrap(Object target, Interceptor interceptor) {
    Map<Class<?>, Set<Method>> signatureMap = getSignatureMap(interceptor);
    Class<?> type = target.getClass();
    Class<?>[] interfaces = getAllInterfaces(type, signatureMap);
    if (interfaces.length > 0) {
      return Proxy.newProxyInstance(
          type.getClassLoader(),
          interfaces,
          new Plugin(target, interceptor, signatureMap));
    }
    return target;
  }

  public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    try {
      Set<Method> methods = signatureMap.get(method.getDeclaringClass());
      if (methods != null && methods.contains(method)) {
        return interceptor.intercept(new Invocation(target, method, args));
      }
      return method.invoke(target, args);
    } catch (Exception e) {
      throw ExceptionUtil.unwrapThrowable(e);
    }
  }

  // 1. 检查是否有 Intercepts 注解
  // 2. 获取 Signature 的方法声明和参数 ,因为存在方法名称相同,参数不同的方法
  // 3. 把方法放入到 signatureMap 中
  private static Map<Class<?>, Set<Method>> getSignatureMap(Interceptor interceptor) {
    Intercepts interceptsAnnotation = interceptor.getClass().getAnnotation(Intercepts.class);
    if (interceptsAnnotation == null) { // issue #251
      throw new PluginException("No @Intercepts annotation was found in interceptor " + interceptor.getClass().getName());
    }
    Signature[] sigs = interceptsAnnotation.value();
    Map<Class<?>, Set<Method>> signatureMap = new HashMap<Class<?>, Set<Method>>();
    for (Signature sig : sigs) {
      Set<Method> methods = signatureMap.get(sig.type());
      if (methods == null) {
        methods = new HashSet<Method>();
        // key 是Class value 是 Method
        signatureMap.put(sig.type(), methods);
      }
      try {
        Method method = sig.type().getMethod(sig.method(), sig.args());
        methods.add(method);
      } catch (NoSuchMethodException e) {
        throw new PluginException("Could not find method on " + sig.type() + " named " + sig.method() + ". Cause: " + e, e);
      }
    }
    return signatureMap;
  }

  private static Class<?>[] getAllInterfaces(Class<?> type, Map<Class<?>, Set<Method>> signatureMap) {
    Set<Class<?>> interfaces = new HashSet<Class<?>>();
    while (type != null) {
      for (Class<?> c : type.getInterfaces()) {
        if (signatureMap.containsKey(c)) {
          interfaces.add(c);
        }
      }
      type = type.getSuperclass();
    }
    return interfaces.toArray(new Class<?>[interfaces.size()]);
  }

}

```

## demo

```java
@Intercepts({
    @Signature(type = Executor.class, method = "commit", args = { boolean.class }),
    @Signature(type = Executor.class, method = "rollback", args = { boolean.class }),
    @Signature(type = Executor.class, method = "close", args = { boolean.class })
})
public class ExecutorInterceptor implements Interceptor {
  public ExecutorInterceptor() {
  }

  private int commitCount;

  private int rollbackCount;

  private boolean closed;

  @Override
  public Object intercept(Invocation invocation) throws Throwable {
    if ("commit".equals(invocation.getMethod().getName())) {
      ++this.commitCount;
    } else if ("rollback".equals(invocation.getMethod().getName())) {
      ++this.rollbackCount;
    } else if ("close".equals(invocation.getMethod().getName())) {
      this.closed = true;
    }

    return invocation.proceed();
  }

  @Override
  public Object plugin(Object target) {
    return Plugin.wrap(target, this);
  }

  @Override
  public void setProperties(Properties properties) {
    // do nothing
  }

  void reset() {
    this.commitCount = 0;
    this.rollbackCount = 0;
    this.closed = false;
  }

  int getCommitCount() {
    return this.commitCount;
  }

  int getRollbackCount() {
    return this.rollbackCount;
  }

  boolean isExecutorClosed() {
    return this.closed;
  }

}
```

## InterceptorChain

```java
public class InterceptorChain {

  private final List<Interceptor> interceptors = new ArrayList<Interceptor>();

  public Object pluginAll(Object target) {
    for (Interceptor interceptor : interceptors) {
      target = interceptor.plugin(target);
    }
    return target;
  }

  public void addInterceptor(Interceptor interceptor) {
    interceptors.add(interceptor);
  }

}
```

## Configuration

> Mybatis 中的 Configuration 会进行 plugin 的解析和初始化

```java

// 初始化  InterceptorChain 所有的  Interceptor 都会放入到 InterceptorChain 中
protected final InterceptorChain interceptorChain = new InterceptorChain();

// 把 Interceptor 添加到 InterceptorChain 中
public void addInterceptor(Interceptor interceptor) {
    interceptorChain.addInterceptor(interceptor);
}

// 下面的 newParameterHandler newResultSetHandler newStatementHandler newExecutor
// 会调用 interceptorChain.pluginAll 方法对 调用 Interceptor 的plugin 方法
// mybatis 提供了 Plugin.wrap(target, this); 工具方法，方便我们生成代理
public ParameterHandler newParameterHandler(MappedStatement mappedStatement, Object parameterObject, BoundSql boundSql) {
  ParameterHandler parameterHandler = new DefaultParameterHandler(mappedStatement, parameterObject, boundSql);
  parameterHandler = (ParameterHandler) interceptorChain.pluginAll(parameterHandler);
  return parameterHandler;
}
public ResultSetHandler newResultSetHandler(Executor executor, MappedStatement mappedStatement, RowBounds rowBounds, ParameterHandler parameterHandler,
    ResultHandler resultHandler, BoundSql boundSql) {
  ResultSetHandler resultSetHandler = mappedStatement.hasNestedResultMaps() ? new NestedResultSetHandler(executor, mappedStatement, parameterHandler, resultHandler, boundSql,
      rowBounds) : new FastResultSetHandler(executor, mappedStatement, parameterHandler, resultHandler, boundSql, rowBounds);
  resultSetHandler = (ResultSetHandler) interceptorChain.pluginAll(resultSetHandler);
  return resultSetHandler;
}
public StatementHandler newStatementHandler(Executor executor, MappedStatement mappedStatement, Object parameterObject, RowBounds rowBounds,    ResultHandler resultHandler, BoundSql boundSql) {
  StatementHandler statementHandler = new RoutingStatementHandler(executor, mappedStatement, parameterObject, rowBounds, resultHandler, boundSql);
  statementHandler = (StatementHandler) interceptorChain.pluginAll(statementHandler);
  return statementHandler;
}
public Executor newExecutor(Transaction transaction) {
  return newExecutor(transaction, defaultExecutorType);
}
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
