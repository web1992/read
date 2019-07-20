# Interceptor

- [Interceptor](#Interceptor)
  - [plugins](#plugins)
  - [Plugin](#Plugin)
    - [wrap](#wrap)
    - [invoke](#invoke)
  - [@Intercepts](#Intercepts)
  - [@Signature](#Signature)
  - [link](#link)

`mybatis` 使用 `Interceptor` 来完成对特定类方法执行的拦截，实现方式是通过 `proxy` 代理拦截指定类的方法的执行

省去你自己实现 `proxy` 的麻烦

## plugins

目前 mybatis 拦截的`类`和类中的`方法`有下面几个

- `Executor` (`update`, `query`, `flushStatements`, `commit`, `rollback`, `getTransaction`, `close`, `isClosed`)
- `ParameterHandler` (`getParameterObject`, `setParameters`)
- `ResultSetHandler` (`handleResultSets`, `handleOutputParameters`)
- `StatementHandler` (`prepare`, `parameterize`, `batch`, `update`, `query`)

## Plugin

```java
// Plugin 类实现了 InvocationHandler
// Plugin 的主要方法是 wrap 和 invoke
public class Plugin implements InvocationHandler {
    // ...
}
```

### wrap

```java
// wrap 类主要是 获取 @Intercepts @Signature 注解中声明的类和方法
// 把解析的结果放在 Map 中
public static Object wrap(Object target, Interceptor interceptor) {
  Map<Class<?>, Set<Method>> signatureMap = getSignatureMap(interceptor);
  Class<?> type = target.getClass();
  Class<?>[] interfaces = getAllInterfaces(type, signatureMap);
  if (interfaces.length > 0) {
    // 生成代理
    return Proxy.newProxyInstance(
        type.getClassLoader(),
        interfaces,
        new Plugin(target, interceptor, signatureMap));
  }
  return target;
}

// 获取所有的类
// 如果有父类，获取所有的父类，（目的就是为当前类和当前类的父类都生成 proxy）
private static Class<?>[] getAllInterfaces(Class<?> type, Map<Class<?>, Set<Method>> signatureMap) {
  Set<Class<?>> interfaces = new HashSet<>();
  while (type != null) {
    for (Class<?> c : type.getInterfaces()) {
      if (signatureMap.containsKey(c)) {
        interfaces.add(c);
      }
    }
    // 如果有父类，获取所有的父类
    type = type.getSuperclass();
  }
  return interfaces.toArray(new Class<?>[interfaces.size()]);
}
```

### invoke

```java
// 如果类和方法在 signatureMap 中，那么就执行 interceptor
@Override
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
```

## @Intercepts

```java
// 必须有 Intercepts 注解
Intercepts interceptsAnnotation = interceptor.getClass().getAnnotation(Intercepts.class);
    // issue #251
    if (interceptsAnnotation == null) {
      throw new PluginException("No @Intercepts annotation was found in interceptor " + interceptor.getClass().getName());
}
```

## @Signature

```java
// Signature 注解用来解决方法重载的问题，
// 如果方法名称和方法参数与注解中的匹配，才会被代理
private static Map<Class<?>, Set<Method>> getSignatureMap(Interceptor interceptor) {
    Intercepts interceptsAnnotation = interceptor.getClass().getAnnotation(Intercepts.class);
    // issue #251
    if (interceptsAnnotation == null) {
      throw new PluginException("No @Intercepts annotation was found in interceptor " + interceptor.getClass().getName());
    }
    Signature[] sigs = interceptsAnnotation.value();
    Map<Class<?>, Set<Method>> signatureMap = new HashMap<>();
      for (Signature sig : sigs) {
      Set<Method> methods = signatureMap.computeIfAbsent(sig.type(), k -> new HashSet<>());
      try {
        Method method = sig.type().getMethod(sig.method(), sig.args());
        methods.add(method);
      } catch (NoSuchMethodException e) {
        throw new PluginException("Could not find method on " + sig.type() + " named " + sig.method() + ". Cause: " + e, e);
      }
    }
    return signatureMap;
}
```

## link

- [http://www.mybatis.org/mybatis-3/configuration.html#plugins](http://www.mybatis.org/mybatis-3/configuration.html#plugins)
