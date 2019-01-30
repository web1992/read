# Filter

- [Filter](#filter)
  - [config](#config)
  - [ProtocolFilterWrapper](#protocolfilterwrapper)
  - [consumer filter](#consumer-filter)
  - [provider filter](#provider-filter)
  - [customer filter](#customer-filter)

`dubbo`中可以通过自定义`Filter`进行执行结果的监控等

## config

配置文件中`org.apache.dubbo.rpc.Filter`与如下的`Filter`:

```config
echo=org.apache.dubbo.rpc.filter.EchoFilter
generic=org.apache.dubbo.rpc.filter.GenericFilter
genericimpl=org.apache.dubbo.rpc.filter.GenericImplFilter
token=org.apache.dubbo.rpc.filter.TokenFilter
accesslog=org.apache.dubbo.rpc.filter.AccessLogFilter
activelimit=org.apache.dubbo.rpc.filter.ActiveLimitFilter
classloader=org.apache.dubbo.rpc.filter.ClassLoaderFilter
context=org.apache.dubbo.rpc.filter.ContextFilter
consumercontext=org.apache.dubbo.rpc.filter.ConsumerContextFilter
exception=org.apache.dubbo.rpc.filter.ExceptionFilter
executelimit=org.apache.dubbo.rpc.filter.ExecuteLimitFilter
deprecated=org.apache.dubbo.rpc.filter.DeprecatedFilter
compatible=org.apache.dubbo.rpc.filter.CompatibleFilter
timeout=org.apache.dubbo.rpc.filter.TimeoutFilter
```

上面的这些都是 `dubbo`自定义的`Filter`,而`Filter`可以分为两类，一个是`consumer`另一个是`provider`

`consumer`对服务调用着拦截，`provider`对服务提供着拦截

## ProtocolFilterWrapper

`ProtocolFilterWrapper`负责对`Filter`进行链接，形成`Filter`链

```java
    private static <T> Invoker<T> buildInvokerChain(final Invoker<T> invoker, String key, String group) {
        Invoker<T> last = invoker;
        // 通过 SPI 获取所有的扩展点
        List<Filter> filters = ExtensionLoader.getExtensionLoader(Filter.class).getActivateExtension(invoker.getUrl(), key, group);
        if (!filters.isEmpty()) {
            for (int i = filters.size() - 1; i >= 0; i--) {
                final Filter filter = filters.get(i);
                final Invoker<T> next = last;
                // 循环对 Filter 进行包装，形成一个链
                last = new Invoker<T>() {

                    @Override
                    public Class<T> getInterface() {
                        return invoker.getInterface();
                    }

                    @Override
                    public URL getUrl() {
                        return invoker.getUrl();
                    }

                    @Override
                    public boolean isAvailable() {
                        return invoker.isAvailable();
                    }

                    @Override
                    public Result invoke(Invocation invocation) throws RpcException {
                        Result result = filter.invoke(next, invocation);
                        if (result instanceof AsyncRpcResult) {
                            AsyncRpcResult asyncResult = (AsyncRpcResult) result;
                            asyncResult.thenApplyWithContext(r -> filter.onResponse(r, invoker, invocation));
                            return asyncResult;
                        } else {
                            return filter.onResponse(result, invoker, invocation);
                        }
                    }

                    @Override
                    public void destroy() {
                        invoker.destroy();
                    }

                    @Override
                    public String toString() {
                        return invoker.toString();
                    }
                };
            }
        }
        return last;
    }
```

## consumer filter

- ConsumerContextFilter
- FutureFilter
- MonitorFilter

## provider filter

- EchoFilter
- ClassLoaderFilter
- GenericFilte
- ContextFilter
- TraceFilter
- TimeoutFilte
- MonitorFilter
- ExceptionFilter

## customer filter

自定义的 Filter 实现

> 实现 `org.apache.dubbo.rpc.Filter` 接口

```java
// group = "consumer" 是必须执行的，这个用来表示，这个 Filter 对客户端的请求进行过滤
// 如果 group = "provider"，这个 Filter 只有在服务端才会被使用
@Activate(group = "consumer")
public class DemoFilter implements Filter {

    private static final Logger logger = LoggerFactory.getLogger(DemoFilter.class);

    @Override
    public Result invoke(Invoker<?> invoker, Invocation invocation) throws RpcException {
        logger.info("DemoFilter#invoke before filter ...");
        Result result = invoker.invoke(invocation);
        logger.info("DemoFilter#invoke after filter ...");
        return result;
    }
}
```

如果是maven项目，放在 `/resources/META-INF/dubbo/` 目录下面,或者 `/resources/META-INF/services/` 目录下面都是可以的

`META-INF/dubbo/org.apache.dubbo.rpc.Filter`

```config
demoFilter=cn.web1992.dubbo.demo.filter.DemoFilter
```

在执行方法的时候就会打印下面的日志：

```log
[30/01/19 18:08:12:846 CST] main  INFO filter.DemoFilter:  [DUBBO] DemoFilter#invoke before filter ..., dubbo version: 2.7.0-SNAPSHOT, current host: 10.108.3.14
[30/01/19 18:08:12:970 CST] main  INFO filter.DemoFilter:  [DUBBO] DemoFilter#invoke after filter ..., dubbo version: 2.7.0-SNAPSHOT, current host: 10.108.3.14
```

> demo:

- [DemoFilter.java java代码](https://github.com/web1992/dubbos/tree/master/dubbo-demo-xml/dubbo-demo-xml-consumer/src/main/java/cn/web1992/dubbo/demo/filter)
- [org.apache.dubbo.rpc.Filter 配置](https://github.com/web1992/dubbos/tree/master/dubbo-demo-xml/dubbo-demo-xml-consumer/src/main/resources/META-INF/services)

> 技巧：

如果自定义的 `Filter` 没有被加载可以在 `ProtocolFilterWrapper#buildInvokerChain` 中进行断点调试，查看具体原因.

```java
// 这里 group=consumer
List<Filter> filters = ExtensionLoader.getExtensionLoader(Filter.class).getActivateExtension(invoker.getUrl(), key, group);
```