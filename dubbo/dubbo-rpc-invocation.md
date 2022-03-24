# RpcInvocation

`org.apache.dubbo.rpc.RpcInvocation`


```java
// RpcInvocation 最终会被序列化协议进行序列化，进行网络传输
public class RpcInvocation implements Invocation, Serializable {

    private static final long serialVersionUID = -4355285085441097045L;

    private String methodName;

    private Class<?>[] parameterTypes;

    private Object[] arguments;

    private Map<String, String> attachments;

    private transient Invoker<?> invoker;

    private transient Class<?> returnType;

    private transient InvokeMode invokeMode;

    public RpcInvocation() {
    }
}
```