# Router

## Router interface

```java
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

## RouterFactory

```java
@SPI
public interface RouterFactory {
    @Adaptive("protocol")
    Router getRouter(URL url);
}
```

- MockRouterFactory -> MockInvokersSelector
- TagRouterFactory -> TagRouter
- AppRouterFactory -> AppRouter
- ServiceRouterFactory -> ServiceRouter