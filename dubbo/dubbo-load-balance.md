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
- RandomLoadBalance #随机(加权随机)
- RoundRobinLoadBalance # 轮询(加权轮询)

默认的实现类是 `RandomLoadBalance`

## ConsistentHashLoadBalance

## RoundRobinLoadBalance

轮询的负载策略,同时支持权重，即:`加权轮询`

```java

// 1. 获取接口全路径+方法名，当做key
// 2. 
@Override
protected <T> Invoker<T> doSelect(List<Invoker<T>> invokers, URL url, Invocation invocation) {
    String key = invokers.get(0).getUrl().getServiceKey() + "." + invocation.getMethodName();
    ConcurrentMap<String, WeightedRoundRobin> map = methodWeightMap.get(key);
    if (map == null) {
        methodWeightMap.putIfAbsent(key, new ConcurrentHashMap<String, WeightedRoundRobin>());
        map = methodWeightMap.get(key);
    }
    int totalWeight = 0;
    long maxCurrent = Long.MIN_VALUE;
    long now = System.currentTimeMillis();
    Invoker<T> selectedInvoker = null;
    WeightedRoundRobin selectedWRR = null;
    // 这个for 循环的作用：
    // 1. 找到计数器最大的那个 invoker
    //    WeightedRoundRobin#current 为计数器
    // 2. 计算总的权重
    for (Invoker<T> invoker : invokers) {
        // 计算服务 key
        String identifyString = invoker.getUrl().toIdentityString();
        WeightedRoundRobin weightedRoundRobin = map.get(identifyString);
        int weight = getWeight(invoker, invocation);
        if (weightedRoundRobin == null) {// 没有则进行初始化map
            weightedRoundRobin = new WeightedRoundRobin();
            weightedRoundRobin.setWeight(weight);
            map.putIfAbsent(identifyString, weightedRoundRobin);
        }
        // 权重更新，则修改
        if (weight != weightedRoundRobin.getWeight()) {
            //weight changed
            weightedRoundRobin.setWeight(weight);
        }
        // 获取&更新当前服务的查询次数
        long cur = weightedRoundRobin.increaseCurrent();
        weightedRoundRobin.setLastUpdate(now);// 更新查询时间
        if (cur > maxCurrent) {// 如果当前的次数大于maxCurrent则更新
            maxCurrent = cur;
            selectedInvoker = invoker;// 更新当前cur 最大的invoker
            selectedWRR = weightedRoundRobin;
        }
        totalWeight += weight;
    }
    // 使用 updateLock 控制并发
    if (!updateLock.get() && invokers.size() != map.size()) {
        if (updateLock.compareAndSet(false, true)) {
            try {
                // copy -> modify -> update reference
                ConcurrentMap<String, WeightedRoundRobin> newMap = new ConcurrentHashMap<String, WeightedRoundRobin>();
                newMap.putAll(map);
                Iterator<Entry<String, WeightedRoundRobin>> it = newMap.entrySet().iterator();
                while (it.hasNext()) {
                    Entry<String, WeightedRoundRobin> item = it.next();
                    // 删除那些时间超过 RECYCLE_PERIOD 对象
                    // RECYCLE_PERIOD = 60000
                    if (now - item.getValue().getLastUpdate() > RECYCLE_PERIOD) {
                        it.remove();
                    }
                }
                methodWeightMap.put(key, newMap);// 更新
            } finally {
                updateLock.set(false);
            }
        }
    }
    if (selectedInvoker != null) {
        // 当前被选择的 invoker 减去总的权重
        // 减少  current 的值
        // 因为上面的 for 循环，总是找 技术最大的，这里把当前的计数器减去权重
        // 那么下次for 循环就会找到一个计数器比较大的invoker
        // 这样就实现了轮询的策略
        selectedWRR.sel(totalWeight);
        return selectedInvoker;
    }
    // should not happen here
    return invokers.get(0);// 保底
}
```

## RandomLoadBalance

随机的负载策略,同时支持权重，即:`加权随机`

```java
// 1. 查询所有 Invoker 的权重，进行相加，同时比较每个 Invoker 的权重是否一样
// 2. 如果权重一样，直接进行随机的选择，否则根据权重进行随机
// 3. getWeight 在获取权重的时候，会检查是否在预热阶段,
//    如果在预热阶段，会对权重进行随机,新的权重的取值范围: 1- weight
protected <T> Invoker<T> doSelect(List<Invoker<T>> invokers, URL url, Invocation invocation) {
    // Number of invokers
    int length = invokers.size();
    // Every invoker has the same weight?
    boolean sameWeight = true;
    // the weight of every invokers
    int[] weights = new int[length];
    // the first invoker's weight
    int firstWeight = getWeight(invokers.get(0), invocation);
    weights[0] = firstWeight;
    // The sum of weights
    int totalWeight = firstWeight;
    for (int i = 1; i < length; i++) {
        int weight = getWeight(invokers.get(i), invocation);
        // save for later use
        weights[i] = weight;
        // Sum
        totalWeight += weight;
        if (sameWeight && weight != firstWeight) {
            sameWeight = false;
        }
    }
    if (totalWeight > 0 && !sameWeight) {
        // If (not every invoker has the same weight & at least one invoker's weight>0), select randomly based on totalWeight.
        int offset = ThreadLocalRandom.current().nextInt(totalWeight);// 根据总的权重，随机一个
        // Return a invoker based on the random value.
        for (int i = 0; i < length; i++) {
            // 用随机到的权重，减去每个invoker的权重，如果小于0，则结束
            // 根据权重的随机写法有很多种，这里不明白这个写法有什么特别的好处...
            offset -= weights[i];
            if (offset < 0) {
                return invokers.get(i);
            }
        }
    }
    // 所有的 invokers 的权重都是一样的,执行这个
    // If all invokers have the same weight value or totalWeight=0, return evenly.
    return invokers.get(ThreadLocalRandom.current().nextInt(length));
}
// 根据启动时间来检查是否在预热阶段
protected int getWeight(Invoker<?> invoker, Invocation invocation) {
    int weight = invoker.getUrl().getMethodParameter(invocation.getMethodName(), Constants.WEIGHT_KEY, Constants.DEFAULT_WEIGHT);
    if (weight > 0) {
        long timestamp = invoker.getUrl().getParameter(Constants.REMOTE_TIMESTAMP_KEY, 0L);
        if (timestamp > 0L) {
            int uptime = (int) (System.currentTimeMillis() - timestamp);
            int warmup = invoker.getUrl().getParameter(Constants.WARMUP_KEY, Constants.DEFAULT_WARMUP);
            if (uptime > 0 && uptime < warmup) {
                weight = calculateWarmupWeight(uptime, warmup, weight);
            }
        }
    }
    return weight >= 0 ? weight : 0;
}
```

## LeastActiveLoadBalance