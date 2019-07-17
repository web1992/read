# Spring AOP APIs

- 01 [Pointcut API in Spring](#1-pointcut-api-in-spring)
- 02 [Operations on pointcuts](#2-operations-on-pointcuts)
- 03 [AspectJ expression pointcuts](#3-aspectj-expression-pointcuts)
- 04 [Convenience pointcut implementations](#4-convenience-pointcut-implementations)
- 05 [Advice API in Spring](#5-advice-api-in-spring)

## 1 Pointcut API in Spring

Let’s look at how Spring handles the crucial pointcut concept.

### Concepts

`org.springframework.aop.Pointcut`

Splitting the Pointcut interface into two parts allows reuse of class and method matching parts, and fine-grained composition operations (such as performing a "union" with another method matcher).

```java
public interface Pointcut {

    ClassFilter getClassFilter();

    MethodMatcher getMethodMatcher();

}
```

ClassFilter

The ClassFilter interface is used to restrict(`限制`) the pointcut to a given set of target classes. If the matches() method always returns true, all target classes will be matched:

```java
public interface ClassFilter {

    boolean matches(Class clazz);
}
```

MethodMatcher

The matches(Method, Class) method is used to test whether this pointcut will ever match a given method on a target class.

```java
public interface MethodMatcher {

    boolean matches(Method m, Class targetClass);

    boolean isRuntime();

    boolean matches(Method m, Class targetClass, Object[] args);
}
```

## 2 Operations on pointcuts

Spring supports operations on pointcuts: notably, union and intersection.

- Union means the methods that either pointcut matches.
- Intersection means the methods that both pointcuts match.
- Union is usually more useful.
- Pointcuts can be composed using the static methods in the org.springframework.aop.support.Pointcuts class, or using the ComposablePointcut class in the same package. However, using AspectJ pointcut expressions is usually a simpler approach.

## 3 AspectJ expression pointcuts

Since 2.0, the most important type of pointcut used by Spring is `org.springframework.aop.aspectj.AspectJExpressionPointcut`. This is a pointcut that uses an AspectJ supplied library to parse an AspectJ pointcut expression string.

See the previous chapter for a discussion of supported AspectJ pointcut primitives.

`org.aspectj.weaver.tools.PointcutPrimitive`

切点表达式

```java
public final class PointcutPrimitive extends TypeSafeEnum {

	public static final PointcutPrimitive CALL = new PointcutPrimitive("call",1);
	public static final PointcutPrimitive EXECUTION = new PointcutPrimitive("execution",2);
	public static final PointcutPrimitive GET = new PointcutPrimitive("get",3);
	public static final PointcutPrimitive SET = new PointcutPrimitive("set",4);
	public static final PointcutPrimitive INITIALIZATION = new PointcutPrimitive("initialization",5);
	public static final PointcutPrimitive PRE_INITIALIZATION = new PointcutPrimitive("preinitialization",6);
	public static final PointcutPrimitive STATIC_INITIALIZATION = new PointcutPrimitive("staticinitialization",7);
	public static final PointcutPrimitive HANDLER = new PointcutPrimitive("handler",8);
	public static final PointcutPrimitive ADVICE_EXECUTION = new PointcutPrimitive("adviceexecution",9);
	public static final PointcutPrimitive WITHIN = new PointcutPrimitive("within",10);
	public static final PointcutPrimitive WITHIN_CODE = new PointcutPrimitive("withincode",11);
	public static final PointcutPrimitive CFLOW = new PointcutPrimitive("cflow",12);
	public static final PointcutPrimitive CFLOW_BELOW = new PointcutPrimitive("cflowbelow",13);
	public static final PointcutPrimitive IF = new PointcutPrimitive("if",14);
	public static final PointcutPrimitive THIS = new PointcutPrimitive("this",15);
	public static final PointcutPrimitive TARGET = new PointcutPrimitive("target",16);
	public static final PointcutPrimitive ARGS = new PointcutPrimitive("args",17);
	public static final PointcutPrimitive REFERENCE = new PointcutPrimitive("reference pointcut",18);
	public static final PointcutPrimitive AT_ANNOTATION = new PointcutPrimitive("@annotation",19);
	public static final PointcutPrimitive AT_THIS = new PointcutPrimitive("@this",20);
	public static final PointcutPrimitive AT_TARGET = new PointcutPrimitive("@target",21);
	public static final PointcutPrimitive AT_ARGS = new PointcutPrimitive("@args",22);
	public static final PointcutPrimitive AT_WITHIN = new PointcutPrimitive("@within",23);
	public static final PointcutPrimitive AT_WITHINCODE = new PointcutPrimitive("@withincode",24);

	private PointcutPrimitive(String name, int key) {
		super(name, key);
	}

}
```

## 4 Convenience pointcut implementations

切点的实现

- Static pointcuts

```java
class TestStaticPointcut extends StaticMethodMatcherPointcut {

    public boolean matches(Method m, Class targetClass) {
        // return true if custom criteria match
    }
}
```

- Regular expression pointcuts

`org.springframework.aop.support.JdkRegexpMethodPointcut`
`RegexpMethodPointcutAdvisor`

- Attribute-driven pointcuts

An important type of static pointcut is a metadata-driven pointcut. This uses the values of metadata attributes: typically, source-level metadata.

- Dynamic pointcuts

- Control flow pointcuts

## 5 Advice API in Spring

### Interception around advice

[link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#aop-api-advice-around)

The most fundamental advice type in Spring is interception around advice.

Spring is compliant with the AOP Alliance interface for around advice using method interception. MethodInterceptors implementing around advice should implement the following interface:

```java
public interface MethodInterceptor extends Interceptor {

    Object invoke(MethodInvocation invocation) throws Throwable;
}
```

### Before advice

A simpler advice type is a before advice. This does not need a MethodInvocation object, since it will only be called before entering the method.

The main advantage of a before advice is that there is no need to invoke the proceed() method, and therefore no possibility of inadvertently failing to proceed down the interceptor chain.

```java
public interface MethodBeforeAdvice extends BeforeAdvice {

    void before(Method m, Object[] args, Object target) throws Throwable;
}
```

异常处理：

Note the return type is void. Before advice can insert custom behavior before the join point executes, but cannot change the return value. If a before advice throws an exception, this will abort further execution of the interceptor chain. The exception will propagate back up the interceptor chain. If it is unchecked, or on the signature of the invoked method, it will be passed directly to the client; otherwise it will be wrapped in an unchecked exception by the AOP proxy.

### Throws advice

```java
public static class CombinedThrowsAdvice implements ThrowsAdvice {

    public void afterThrowing(RemoteException ex) throws Throwable {
        // Do something with remote exception
    }

    public void afterThrowing(Method m, Object[] args, Object target, ServletException ex) {
        // Do something with all arguments
    }
}
```

### Introduction advice

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#aop-api-advice-introduction)

### Proxying classes

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#aop-api-proxying-class)

### Creating AOP proxies programmatically with the ProxyFactory

```java
ProxyFactory factory = new ProxyFactory(myBusinessInterfaceImpl);
factory.addAdvice(myMethodInterceptor);
factory.addAdvisor(myAdvisor);
MyBusinessInterface tb = (MyBusinessInterface) factory.getProxy();
```