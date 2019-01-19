# ExtensionLoader

1. 分析 `ExtensionLoader` 的实现
2. 通过`ServiceBean`中的`protocol.export`加载过程，分析 `dubbo` 自适应的实现方式

来自 `org.apache.dubbo.config.ServiceConfig`  中的源码注释

```java

/**
     * The {@link Protocol} implementation with adaptive functionality,it will be different in different scenarios.
     * A particular {@link Protocol} implementation is determined by the protocol attribute in the {@link URL}.
     * For example:
     *
     * <li>when the url is registry://224.5.6.7:1234/org.apache.dubbo.registry.RegistryService?application=dubbo-sample,
     * then the protocol is <b>RegistryProtocol</b></li>
     *
     * <li>when the url is dubbo://224.5.6.7:1234/org.apache.dubbo.config.api.DemoService?application=dubbo-sample, then
     * the protocol is <b>DubboProtocol</b></li>
     * <p>
     * Actually，when the {@link ExtensionLoader} init the {@link Protocol} instants,it will automatically wraps two
     * layers, and eventually will get a <b>ProtocolFilterWrapper</b> or <b>ProtocolListenerWrapper</b>
     */
private static final Protocol protocol = ExtensionLoader.getExtensionLoader(Protocol.class).getAdaptiveExtension();
```

- `Protocol`实现了接口自适应功能（自适应：根据参数的不同来选择不同的实现类进行调用）

如这个方法：

```java
 Exporter<?> exporter = protocol.export(wrapperInvoker);
```

`wrapperInvoker`是一个`org.apache.dubbo.rpc.Invoker`对象，Invoker 继承了 `org.apache.dubbo.common.Node`类
Node 类中有`URL getUrl();` 这个方法可以返回 URL 对象.

一个例子：如果 URL 中参数是`registry`的时候，调用的实现就是`RegistryProtocol`的`export`
如果 URL 中参数是`dubbo`的时候，调用的实现就是`DubboProtocol`的`export`

## Protocol\$Adaptive

`ExtensionLoader.getExtensionLoader(Protocol.class).getAdaptiveExtension();`这个返回的 `protocol` 是包装之后的一个 `包装类`

具体的代码实现逻辑如下：

下面的代码是通过`ExtensionLoader#createAdaptiveExtensionClassCode`这个方法拼接而成的一个类，而后通过编译这个类，生成`Protocol$Adaptive`

其它`自适应`类的实现可以在这里预览下:[dubbo adaptive class](https://github.com/web1992/dubbos/tree/master/dubbo-source-code/src/main/java/cn/web1992)

- Cluster\$Adaptive
- Dispatcher\$Adaptive
- Protocol\$Adaptive
- ProxyFactory\$Adaptive
- RegistryFactory\$Adaptive
- ThreadPool\$Adaptive
- Transporter\$Adaptive
- Validation\$Adaptive

```java
package cn.web1992;

import org.apache.dubbo.common.extension.ExtensionLoader;

public class Protocol$Adaptive implements org.apache.dubbo.rpc.Protocol {
    public void destroy() {
        throw new UnsupportedOperationException("method public abstract void org.apache.dubbo.rpc.Protocol.destroy() of interface org.apache.dubbo.rpc.Protocol is not adaptive method!");
    }

    public int getDefaultPort() {
        throw new UnsupportedOperationException("method public abstract int org.apache.dubbo.rpc.Protocol.getDefaultPort() of interface org.apache.dubbo.rpc.Protocol is not adaptive method!");
    }

    public org.apache.dubbo.rpc.Exporter export(org.apache.dubbo.rpc.Invoker arg0) throws org.apache.dubbo.rpc.RpcException {
        if (arg0 == null) {
            throw new IllegalArgumentException("org.apache.dubbo.rpc.Invoker argument == null");
        }
        if (arg0.getUrl() == null) {
            throw new IllegalArgumentException("org.apache.dubbo.rpc.Invoker argument getUrl() == null");
        }
        org.apache.dubbo.common.URL url = arg0.getUrl();
        String extName = (url.getProtocol() == null ? "dubbo" : url.getProtocol());
        if (extName == null) {
            throw new IllegalStateException("Fail to get extension(org.apache.dubbo.rpc.Protocol) name from url(" + url.toString() + ") use keys([protocol])");
        }
        org.apache.dubbo.rpc.Protocol extension = (org.apache.dubbo.rpc.Protocol) ExtensionLoader.getExtensionLoader(org.apache.dubbo.rpc.Protocol.class).getExtension(extName);
        return extension.export(arg0);
    }

    public org.apache.dubbo.rpc.Invoker refer(java.lang.Class arg0, org.apache.dubbo.common.URL arg1) throws org.apache.dubbo.rpc.RpcException {
        if (arg1 == null) {
            throw new IllegalArgumentException("url == null");
        }
        org.apache.dubbo.common.URL url = arg1;
        String extName = (url.getProtocol() == null ? "dubbo" : url.getProtocol());
        if (extName == null) {
            throw new IllegalStateException("Fail to get extension(org.apache.dubbo.rpc.Protocol) name from url(" + url.toString() + ") use keys([protocol])");
        }
        org.apache.dubbo.rpc.Protocol extension = (org.apache.dubbo.rpc.Protocol) ExtensionLoader.getExtensionLoader(org.apache.dubbo.rpc.Protocol.class).getExtension(extName);
        return extension.refer(arg0, arg1);
    }
}
```

可以看到`export`这个方法有一个参数`org.apache.dubbo.rpc.Invoker`，从`getUrl()`获取一个`org.apache.dubbo.common.URL`对象

然后获取`protocol`，如果为空，默认是`dubbo`，然后通过 `ExtensionLoader.getExtensionLoader` 去加载具体的实现类
