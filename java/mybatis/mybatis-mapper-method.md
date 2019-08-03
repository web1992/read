# MapperMethod

## init

```java
// 1.
// 2.
// 3.
// 4.
public MapperMethod(Class<?> declaringInterface, Method method, SqlSession sqlSession) {
    paramNames = new ArrayList<String>();
    paramPositions = new ArrayList<Integer>();
    this.sqlSession = sqlSession;
    this.method = method;
    this.config = sqlSession.getConfiguration();
    this.hasNamedParameters = false;
    this.declaringInterface = declaringInterface;
    this.objectFactory = config.getObjectFactory();
    setupFields();// this.commandName = declaringInterface.getName() + "." + method.getName();
    setupMethodSignature();
    setupCommandType();// UNKNOWN, INSERT, UPDATE, DELETE, SELECT;
    validateStatement();
}
```

```java
// 1. 处理返回值返回值是否为空
// 2. 是否返回多个值
// 3. 返回类型是否是map,是处理 MapKey
// 4. 处理方法的参数
// 5. RowBounds 只能有一个
// 6. ResultHandler 只能有一个
// 7. paramNames List<String> paramNames;
// 8. paramPositions List<Integer> paramPositions;
private void setupMethodSignature() {
  if (method.getReturnType().equals(Void.TYPE)) {
    returnsVoid = true;
  }
  if (objectFactory.isCollection(method.getReturnType()) || method.getReturnType().isArray()) {
    returnsMany = true;
  }
  if (Map.class.isAssignableFrom(method.getReturnType())) {
    final MapKey mapKeyAnnotation = method.getAnnotation(MapKey.class);
    if (mapKeyAnnotation != null) {
      mapKey = mapKeyAnnotation.value();
      returnsMap = true;
    }
  }
  final Class<?>[] argTypes = method.getParameterTypes();
  for (int i = 0; i < argTypes.length; i++) {
    if (RowBounds.class.isAssignableFrom(argTypes[i])) {
      if (rowBoundsIndex == null) {
        rowBoundsIndex = i;
      } else {
        throw new BindingException(method.getName() + " cannot have multiple RowBounds parameters");
      }
    } else if (ResultHandler.class.isAssignableFrom(argTypes[i])) {
      if (resultHandlerIndex == null) {
        resultHandlerIndex = i;
      } else {
        throw new BindingException(method.getName() + " cannot have multiple ResultHandler parameters");
      }
    } else {
      String paramName = String.valueOf(paramPositions.size());
      paramName = getParamNameFromAnnotation(i, paramName);
      paramNames.add(paramName);
      paramPositions.add(i);
    }
  }
}
```

## execute

```java
// 1. 增删改查的处理
// 2. 查询则根据查询的参数和返回类型，做不同的处理
//    如：Map,RowBounds,ResultHandler
public Object execute(Object[] args) {
  Object result = null;
  if (SqlCommandType.INSERT == type) {
    Object param = getParam(args);
    // insert
    result = sqlSession.insert(commandName, param);
  } else if (SqlCommandType.UPDATE == type) {
    Object param = getParam(args);
    // update
    result = sqlSession.update(commandName, param);
  } else if (SqlCommandType.DELETE == type) {
    Object param = getParam(args);
    // delete
    result = sqlSession.delete(commandName, param);
  } else if (SqlCommandType.SELECT == type) {
    if (returnsVoid && resultHandlerIndex != null) {
      // 1. ResultHandler,RowBounds
      executeWithResultHandler(args);
    } else if (returnsMany) {
      // 2. Collection Array
      result = executeForMany(args);
    } else if (returnsMap) {
      // 3. Map
      result = executeForMap(args);
    } else {
      // 4. 其他
      Object param = getParam(args);
      result = sqlSession.selectOne(commandName, param);
    }
  } else {
    throw new BindingException("Unknown execution method for: " + commandName);
  }
  return result;
}
```

## ResultHandler

## RowBounds
