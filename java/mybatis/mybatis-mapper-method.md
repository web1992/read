# MapperMethod

## execute

```java
public Object execute(Object[] args) {
  Object result = null;
  if (SqlCommandType.INSERT == type) {
    Object param = getParam(args);
    result = sqlSession.insert(commandName, param);
  } else if (SqlCommandType.UPDATE == type) {
    Object param = getParam(args);
    result = sqlSession.update(commandName, param);
  } else if (SqlCommandType.DELETE == type) {
    Object param = getParam(args);
    result = sqlSession.delete(commandName, param);
  } else if (SqlCommandType.SELECT == type) {
    if (returnsVoid && resultHandlerIndex != null) {
      executeWithResultHandler(args);
    } else if (returnsMany) {
      result = executeForMany(args);
    } else if (returnsMap) {
      result = executeForMap(args);
    } else {
      Object param = getParam(args);
      result = sqlSession.selectOne(commandName, param);
    }
  } else {
    throw new BindingException("Unknown execution method for: " + commandName);
  }
  return result;
}
```
