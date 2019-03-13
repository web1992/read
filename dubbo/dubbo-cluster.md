# Cluster

## uml

![Cluster](images/dubbo-cluster.png)

## Directory

```java
public interface Directory<T> extends Node {
    Class<T> getInterface();
    List<Invoker<T>> list(Invocation invocation) throws RpcException;
}
```