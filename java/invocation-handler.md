# InvocationHandler

- [InvocationHandler](https://www.cnblogs.com/xiaoluo501395377/p/3383130.html)

## org.apache.dubbo.rpc.proxy.InvokerInvocationHandler

`dubbo` 中使用 `InvocationHandler`,生成方法的代理，包装了 `Invoker`,当调用方式时，所有的方法都会进入 `invoke` 方法

通过 `Invoker` 其他调用远程的 `TCP` 服务,实现 rpc 的调用

```java
public class InvokerInvocationHandler implements InvocationHandler {
    private static final Logger logger = LoggerFactory.getLogger(InvokerInvocationHandler.class);
    private final Invoker<?> invoker;

    public InvokerInvocationHandler(Invoker<?> handler) {
        this.invoker = handler;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        String methodName = method.getName();
        Class<?>[] parameterTypes = method.getParameterTypes();
        if (method.getDeclaringClass() == Object.class) {
            return method.invoke(invoker, args);
        }
        if ("toString".equals(methodName) && parameterTypes.length == 0) {
            return invoker.toString();
        }
        if ("hashCode".equals(methodName) && parameterTypes.length == 0) {
            return invoker.hashCode();
        }
        if ("equals".equals(methodName) && parameterTypes.length == 1) {
            return invoker.equals(args[0]);
        }

        return invoker.invoke(createInvocation(method, args)).recreate();
    }

    private RpcInvocation createInvocation(Method method, Object[] args) {
        RpcInvocation invocation = new RpcInvocation(method, args);
        if (RpcUtils.hasFutureReturnType(method)) {
            invocation.setAttachment(Constants.FUTURE_RETURNTYPE_KEY, "true");
            invocation.setAttachment(Constants.ASYNC_KEY, "true");
        }
        return invocation;
    }

}
```