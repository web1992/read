# Exporter

`Exporter` 在 `dubbo` 负责包装 `provider` 端的 `Invoker`

## interface

```java
public interface Exporter<T> {
    Invoker<T> getInvoker();
    void unexport();
}
```

## Exporter and Protocol

而 `Exporter` 由 `Protocol` 的 `export` 方法生成的

```java
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

## provider export

`provider` 端的 `export` 生成

```java
// DubboProtocol
// 下面的这段代码会再 provider 启动的时候执行
@Override
public <T> Exporter<T> export(Invoker<T> invoker) throws RpcException {
    URL url = invoker.getUrl();
    // export service.
    String key = serviceKey(url);
    // 包装 invoker 生成 DubboExporter
    // 然后放入到 DubboExporter 中
    DubboExporter<T> exporter = new DubboExporter<T>(invoker, key, exporterMap);
    exporterMap.put(key, exporter);
    // 省略其它代码
    return exporter;
}
```

`provider` 端的 `export` 使用

```java
// 下面的代码会再客户端的请求到来的时候执行
// 在 DubboProtocol 的内部类 ExchangeHandler
Invoker<?> getInvoker(Channel channel, Invocation inv) throws RemotingException {
    // 省略其它代码
    String serviceKey = serviceKey(port, path, inv.getAttachments().get(Constants.VERSION_KEY), inv.getAttachments().get(Constants.GROUP_KEY));
    // 从 exporterMap 中查询 DubboExporter
    DubboExporter<?> exporter = (DubboExporter<?>) exporterMap.get(serviceKey);
    if (exporter == null) {
        throw new RemotingException(channel, "Not found exported service: " + serviceKey + " in " + exporterMap.keySet() + ", may be version or group mismatch " +
                ", channel: consumer: " + channel.getRemoteAddress() + " --> provider: " + channel.getLocalAddress() + ", message:" + inv);
    }
    return exporter.getInvoker();
}
```