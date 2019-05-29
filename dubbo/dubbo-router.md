# Router

`Router` `dubbo` 服务动态路由的实现

`dubbo` `2.7` 版本中对 `Router` 进行了增强，可参考 [http://dubbo.apache.org/zh-cn/blog/dubbo-27-features.html](http://dubbo.apache.org/zh-cn/blog/dubbo-27-features.html)

- [Router](#router)
  - [Router interface](#router-interface)
  - [Router implement](#router-implement)
  - [Router init](#router-init)
  - [RouterFactory](#routerfactory)
  - [TagRouter](#tagrouter)
  - [AppRouter](#approuter)
  - [ServiceRouter](#servicerouter)

## Router interface

```java
// 接口定义
public interface Router extends Comparable<Router> {

    int DEFAULT_PRIORITY = Integer.MAX_VALUE;

    URL getUrl();

    <T> List<Invoker<T>> route(List<Invoker<T>> invokers, URL url, Invocation invocation) throws RpcException;

    default <T> void notify(List<Invoker<T>> invokers) {

    }

    boolean isRuntime();

    boolean isForce();

    int getPriority();

    @Override
    default int compareTo(Router o) {
        if (o == null) {
            throw new IllegalArgumentException();
        }
        return Integer.compare(this.getPriority(), o.getPriority());
    }
}
```

## Router implement

- AppRouter
- ConditionRouter
- ScriptRouter
- ServiceRouter
- TagRouter

## Router init

```java
// RegistryDirectory
// router 是在 RegistryDirectory 的 buildRouterChain 方法中执行的
public void buildRouterChain(URL url) {
    this.setRouterChain(RouterChain.buildChain(url));
}

// 最终会执行这个构造方法
// 通过 dubbo 的 SPI 机制去 加载 RouterFactory 并创建 Router
private RouterChain(URL url) {
    // 这里会加载所有  @Activate 注解的 RouterFactory 实现类
    List<RouterFactory> extensionFactories = ExtensionLoader.getExtensionLoader(RouterFactory.class)
            .getActivateExtension(url, (String[]) null);
    List<Router> routers = extensionFactories.stream()
            .map(factory -> factory.getRouter(url))
            .collect(Collectors.toList());
    initWithRouters(routers);
}
```

![RouterFactory](./images/dubbo-RouterFactory.png)

`Router` 在一个 `RPC` 调用链的位置，可参考：[dubbo-protocol-registry-protocol.md](dubbo-protocol-registry-protocol.md#cluster-and-router-and-directory)

## RouterFactory

```java
@SPI
public interface RouterFactory {
    @Adaptive("protocol")
    Router getRouter(URL url);
}
```

旧的 Router

- MockRouterFactory -> MockInvokersSelector
- ConditionRouterFactory -> ConditionRouter
- ScriptRouterFactory -> ScriptRouter

dubbo 2.7 新的 Router

- TagRouterFactory -> TagRouter
- AppRouterFactory -> AppRouter
- ServiceRouterFactory -> ServiceRouter

可动态修改的 Router

- ListenableRouter

`ServiceRouter` 和 `AppRouter` 继承了 `ListenableRouter` 实现了动态修改路由的功能

可参考 [dubbo-dynamic-configuration.md](dubbo-dynamic-configuration.md)

## TagRouter

## AppRouter

## ServiceRouter