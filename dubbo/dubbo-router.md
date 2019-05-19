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

## interface

- AppRouter
- ConditionRouter
- ScriptRouter
- ServiceRouter
- TagRouter

## RouterFactory

```java
@SPI
public interface RouterFactory {

    @Adaptive("protocol")
    Router getRouter(URL url);
}
```
