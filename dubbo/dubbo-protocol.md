# Protocol

`Protocol`中主要有两个方法：`export`和`refer`

`Protocol`的两个主要的实现类是`DubboProtocol`和`RegistryProtocol`

`Protocol` 源码链接 [Protocol.java](https://github.com/apache/incubator-dubbo/blob/master/dubbo-rpc/dubbo-rpc-api/src/main/java/org/apache/dubbo/rpc/Protocol.java)

```java

// Protocol 中的主要方法是 export 和 refer
// 通过 export 方法，暴露，注册服务
// 通过 refer 方法，发现，订阅服务
// expor 主要是服务器相关的业务，如启用一个 Netty 服务，并暴露服务
// refer 主要是客户端相关的业务，如注册，订阅一个服务
// destroy 负责服务的关闭，取消注册，取消订阅
// 如果要完全理解 Protocol 的功能，理解`RegistryProtocol` 和 `DubboProtocol` 的实现就可以
// export 返回的Exporter实例，refer 返回的Invoker 实例都是经过层层包装的包装类，从而实现 Filter 等功能
// 包装类的生成有些是在代码中写死的，而有些是通过 SPI 机制生成的包装对象
@SPI("dubbo")
public interface Protocol {

    int getDefaultPort();

    @Adaptive
    <T> Exporter<T> export(Invoker<T> invoker) throws RpcException;
  
    @Adaptive
    <T> Invoker<T> refer(Class<T> type, URL url) throws RpcException;

    void destroy();

}
```

## DubboProtocol

> DubboProtocol#export

```java
    // export 这个方法主要给服务提供者（provider）使用
    @Override
    public <T> Exporter<T> export(Invoker<T> invoker) throws RpcException {
        URL url = invoker.getUrl();

        // export service.
        String key = serviceKey(url);
        DubboExporter<T> exporter = new DubboExporter<T>(invoker, key, exporterMap);
        exporterMap.put(key, exporter);

        //export an stub service for dispatching event
        Boolean isStubSupportEvent = url.getParameter(Constants.STUB_EVENT_KEY, Constants.DEFAULT_STUB_EVENT);
        Boolean isCallbackservice = url.getParameter(Constants.IS_CALLBACK_SERVICE, false);
        if (isStubSupportEvent && !isCallbackservice) {
            String stubServiceMethods = url.getParameter(Constants.STUB_EVENT_METHODS_KEY);
            if (stubServiceMethods == null || stubServiceMethods.length() == 0) {
                if (logger.isWarnEnabled()) {
                    logger.warn(new IllegalStateException("consumer [" + url.getParameter(Constants.INTERFACE_KEY) +
                            "], has set stubproxy support event ,but no stub methods founded."));
                }
            } else {
                stubServiceMethodsMap.put(url.getServiceKey(), stubServiceMethods);
            }
        }
        // openServer 方法会创建一个 TCP 服务
        openServer(url);
        optimizeSerialization(url);
        return exporter;
    }
```

> DubboProtocol#refer

```java
    // 这个服务给 client 端使用
    @Override
    public <T> Invoker<T> refer(Class<T> serviceType, URL url) throws RpcException {
        optimizeSerialization(url);
        // create rpc invoker.
        // getClients 方法会创建客户端与服务器的连接
        DubboInvoker<T> invoker = new DubboInvoker<T>(serviceType, url, getClients(url), invokers);
        invokers.add(invoker);
        return invoker;
    }
```

## RegistryProtocol
