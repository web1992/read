# Registry

`dubbo` 是支持集群的，同时也提供了服务的动态发现，注册功能，而这些功能的实现就是 `Registry` 接口

`Registry` 是通过 `RegistryFactory` 创建的，而 `RegistryFactory` 实现了 `dubbo` 自适应

## RegistryService

```java
// 接口中定义的方法
public interface RegistryService {
    void register(URL url);
    void unregister(URL url);
    void subscribe(URL url, NotifyListener listener);
    void unsubscribe(URL url, NotifyListener listener);
    List<URL> lookup(URL url);
}
```

## AbstractRegistry

## FailbackRegistry

## MulticastRegistry

`多播注册`(注意这里不是 `广播`)

![MulticastRegistry](images/dubbo-registry-multicast.png)

## ZookeeperRegistry

基于 `zookeeper`的服务注册发现

![ZookeeperRegistry](images/dubbo-registry-zookeeper.png)