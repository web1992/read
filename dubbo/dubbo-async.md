# Dubbo async

> Dubbo 异步的实现

`Dubbo` 中对方法的执行结果封装成了 `Result`,`Result` 的实现有同步的，有异步的

- RpcResult
- DecodeableRpcResult
- AsyncRpcResult

## InvokerInvocationHandler

`org.apache.dubbo.rpc.proxy.InvokerInvocationHandler`

```java
// Result#recreate
return invoker.invoke(new RpcInvocation(method, args)).recreate();
```

看下下面的 `Invoker` 实现 `invoke` 方法的返回结果就是 `Result`

```java
public interface Invoker<T> extends Node {

    Class<T> getInterface();
    Result invoke(Invocation invocation) throws RpcException;

}
```

`Dubbo` 使用 `Proxy` + `InvokerInvocationHandler` 使用代理模仿接口的实现，当调研接口的方法的时候

其实是调用 `Dubbo` 的代理方法，这个方法最终会被执行到 [DubboInvoker](dubbo-invoker.md)

## RPC 执行链

TODO

## RpcResult

`org.apache.dubbo.rpc.RpcResult`

## DecodeableRpcResult

`org.apache.dubbo.rpc.protocol.dubbo.DecodeableRpcResult`

## AsyncRpcResult

`org.apache.dubbo.rpc.AsyncRpcResult`

## AppResponse

`org.apache.dubbo.rpc.AppResponse`
