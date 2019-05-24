# LoadBalance

`LoadBalance` 负载均衡。 `dubbo` 中的服务提供这可以有多个，为了使每个服务提供者

收到的请求都是均匀的，引入负责均衡策略

## interface

```java
@SPI(RandomLoadBalance.NAME)
public interface LoadBalance {
    @Adaptive("loadbalance")
    <T> Invoker<T> select(List<Invoker<T>> invokers, URL url, Invocation invocation) throws RpcException;
}
```

## implement

- ConsistentHashLoadBalance #一致的哈希
- LeastActiveLoadBalance #最不活跃
- RandomLoadBalance #随机
- RoundRobinLoadBalance # 轮询

默认的实现类是 `RandomLoadBalance`

## ConsistentHashLoadBalance

## RoundRobinLoadBalance

## RandomLoadBalance

## LeastActiveLoadBalance