# MapperProxy

## MapperProxy class

```java
public class MapperProxy implements InvocationHandler, Serializable {

  private static final long serialVersionUID = -6424540398559729838L;
  private SqlSession sqlSession;
  //...

public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    if (method.getDeclaringClass() == Object.class) {
      return method.invoke(this, args);
    }
    final Class<?> declaringInterface = findDeclaringInterface(proxy, method);
    final MapperMethod mapperMethod = new MapperMethod(declaringInterface, method, sqlSession);
    final Object result = mapperMethod.execute(args);
    if (result == null && method.getReturnType().isPrimitive() && !method.getReturnType().equals(Void.TYPE)) {
      throw new BindingException("Mapper method '" + method.getName() + "' (" + method.getDeclaringClass() + ") attempted to return null from a method with a primitive return type (" + method.getReturnType() + ").");
    }
    return result;
  }
}
```

## MapperMethod

[MapperMethod](mybatis-mapper-method.md)

## MapperRegistry

```java
// Configuration
public <T> void addMapper(Class<T> type) {
  mapperRegistry.addMapper(type);
}
public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
  return mapperRegistry.getMapper(type, sqlSession);
}
public boolean hasMapper(Class<?> type) {
  return mapperRegistry.hasMapper(type);
}
```

## MapperProxyFactory

## MapperAnnotationBuilder

## XMLMapperBuilder

```java
public void parse() {
    if (!configuration.isResourceLoaded(resource)) {
      configurationElement(parser.evalNode("/mapper"));
      configuration.addLoadedResource(resource);
      bindMapperForNamespace();
    }

    parsePendingResultMaps();
    parsePendingCacheRefs();
    parsePendingStatements();
}
```
