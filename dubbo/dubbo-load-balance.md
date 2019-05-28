# LoadBalance

`LoadBalance` 负载均衡。 `dubbo` 中的服务提供者可以有多个，为了使每个服务提供者

收到的请求都是均匀的(或者方便自己控制服务的流量)，引入负载均衡策略

- [LoadBalance](#loadbalance)
  - [interface](#interface)
  - [implement](#implement)
  - [ConsistentHashLoadBalance](#consistenthashloadbalance)
  - [RoundRobinLoadBalance](#roundrobinloadbalance)
  - [RandomLoadBalance](#randomloadbalance)
  - [LeastActiveLoadBalance](#leastactiveloadbalance)

## interface

```java
// 接口定义也很简单，目的就是从 List<Invoker<T>> 集合中，根据不同的策略，选取一个 Invoker
@SPI(RandomLoadBalance.NAME)
public interface LoadBalance {
    @Adaptive("loadbalance")
    <T> Invoker<T> select(List<Invoker<T>> invokers, URL url, Invocation invocation) throws RpcException;
}
```

## implement

已经有的实现类:

- ConsistentHashLoadBalance #一致性的哈希
- LeastActiveLoadBalance #最不活跃
- RandomLoadBalance #随机(加权随机)
- RoundRobinLoadBalance # 轮询(加权轮询)

默认的实现类是 `RandomLoadBalance`

## ConsistentHashLoadBalance

一致性哈希负载均衡，使用 `hash` 算法

> 一致性哈希算法，主要是用来解决分布式缓存的问题，具体可参照下面的链接
>
> 这里简单的说明下使用 hash 在分布式系统中的问题：
>
> 1. 当分布式系统中的节点变化的时候，需要重新进行hash
> 2. 当分布式的节点较少时，可能存在 hash 不均匀的情况，导致某一个节点压力巨大

而 `ConsistentHashLoadBalance` 针对上线的问题进行了处理,使用 `identityHashCode`和`虚拟节点` 来解决上面的问题

[​一致性哈希 (Consistent hashing)](https://coderxing.gitbooks.io/architecture-evolution/di-san-pian-ff1a-bu-luo/631-yi-zhi-xing-ha-xi.html)

```java
// 1. 计算hash值，进行缓存，同时使用虚拟节点，避免 hash 分布不均匀的情况
// 2. 计算hash,从缓存中查找 invoker
// 3. 使用对象的 identityHashCode 来检查 invokers 的变化（服务上线，下线）重新生成hash
protected <T> Invoker<T> doSelect(List<Invoker<T>> invokers, URL url, Invocation invocation) {
    String methodName = RpcUtils.getMethodName(invocation);
    String key = invokers.get(0).getUrl().getServiceKey() + "." + methodName;
    int identityHashCode = System.identityHashCode(invokers);
    ConsistentHashSelector<T> selector = (ConsistentHashSelector<T>) selectors.get(key);
    if (selector == null || selector.identityHashCode != identityHashCode) {
        selectors.put(key, new ConsistentHashSelector<T>(invokers, methodName, identityHashCode));
        selector = (ConsistentHashSelector<T>) selectors.get(key);
    }
    return selector.select(invocation);
}

// 对 Invoker 进行hash 计算，进行缓存
private static final class ConsistentHashSelector<T> {
    private final TreeMap<Long, Invoker<T>> virtualInvokers;
    private final int replicaNumber;
    private final int identityHashCode;
    private final int[] argumentIndex;
    ConsistentHashSelector(List<Invoker<T>> invokers, String methodName, int identityHashCode) {
        this.virtualInvokers = new TreeMap<Long, Invoker<T>>();
        this.identityHashCode = identityHashCode;
        URL url = invokers.get(0).getUrl();
        // 副本数量,默认为160
        this.replicaNumber = url.getMethodParameter(methodName, HASH_NODES, 160);
        String[] index = COMMA_SPLIT_PATTERN.split(url.getMethodParameter(methodName, HASH_ARGUMENTS, "0"));
        argumentIndex = new int[index.length];
        for (int i = 0; i < index.length; i++) {
            argumentIndex[i] = Integer.parseInt(index[i]);
        }
        for (Invoker<T> invoker : invokers) {
            String address = invoker.getUrl().getAddress();
            // 为每个 invoker 生成 160 个副本
            for (int i = 0; i < replicaNumber / 4; i++) {
                byte[] digest = md5(address + i);
                for (int h = 0; h < 4; h++) {
                    long m = hash(digest, h);
                    virtualInvokers.put(m, invoker);
                }
            }
        }
    }
    public Invoker<T> select(Invocation invocation) {
        String key = toKey(invocation.getArguments());
        byte[] digest = md5(key);
        return selectForKey(hash(digest, 0));
    }
    private String toKey(Object[] args) {
        StringBuilder buf = new StringBuilder();
        for (int i : argumentIndex) {
            if (i >= 0 && i < args.length) {
                buf.append(args[i]);
            }
        }
        return buf.toString();
    }
    // 从虚拟节点中查找 invoker
    private Invoker<T> selectForKey(long hash) {
        // ceilingEntry 找到一个大于等于 hash 的 Map.Entry
        // 可以参考上面一致性hash 的文章
        Map.Entry<Long, Invoker<T>> entry = virtualInvokers.ceilingEntry(hash);
        if (entry == null) {// 没有找到使用第一个
            entry = virtualInvokers.firstEntry();
        }
        return entry.getValue();
    }
    private long hash(byte[] digest, int number) {
        return (((long) (digest[3 + number * 4] & 0xFF) << 24)
                | ((long) (digest[2 + number * 4] & 0xFF) << 16)
                | ((long) (digest[1 + number * 4] & 0xFF) << 8)
                | (digest[number * 4] & 0xFF))
                & 0xFFFFFFFFL;
    }
    private byte[] md5(String value) {
        MessageDigest md5;
        try {
            md5 = MessageDigest.getInstance("MD5");
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e.getMessage(), e);
        }
        md5.reset();
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        md5.update(bytes);
        return md5.digest();
    }
}
```

## RoundRobinLoadBalance

轮询的负载策略,同时支持权重，即:`加权轮询`

```java
// 1. 获取接口全路径+方法名，当做key,进行缓存
// 2. 通过维护一个权重，找到权重最大的那个 invoker,减少权重并返回 invoker
// 3. List<Invoker> 的大小，会增大或者变小。变小,意味着服务下线，需要把内存中的无用对象删除
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
    // 这个 for 循环的作用：
    // 1. 找到权重最大的那个 invoker
    //    WeightedRoundRobin#current 为权重
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
        // 获取&更新当前服务的权重
        long cur = weightedRoundRobin.increaseCurrent();
        weightedRoundRobin.setLastUpdate(now);// 更新使用时间
        // 下面的代码就是找到一个计权重最大的 invoker
        if (cur > maxCurrent) {// 如果当前的权重大于 maxCurrent 则更新
            maxCurrent = cur;
            selectedInvoker = invoker;// 更新当前 cur 最大的 invoker
            selectedWRR = weightedRoundRobin;
        }
        totalWeight += weight;
    }
    // 使用 updateLock 控制并发
    // 服务存在上线，下线这个操作，因此 invokers 的size 不等于 size 的时候
    // 服务可能下线了，那么久需要把 map 中的对象删除
    // 检查那个超过 60 秒没有使用的，从内存中删除
    // 避免内存泄露
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
        // 减少当前服务器权重的值
        // 因为上面的 for 循环，总是找权重最大的，这里把当前的权重减去总的权重
        // 那么下次for 循环就会找到一个权重比较大的invoker
        // 这样就实现了轮询的策略（当前的权重weight 越大，那么current-减去总权重，剩余的值也就越大）
        selectedWRR.sel(totalWeight);// 减少更新权重
        return selectedInvoker;
    }
    // should not happen here
    return invokers.get(0);// 保底
}
// 权重轮询
protected static class WeightedRoundRobin {
    private int weight;// 权重
    private AtomicLong current = new AtomicLong(0);// 当前的权重
    private long lastUpdate;
    public int getWeight() {
        return weight;
    }
    public void setWeight(int weight) {
        this.weight = weight;
        current.set(0);// 初始化的时候，权重设置成0
    }
    public long increaseCurrent() {// 增加权重
        return current.addAndGet(weight);
    }
    public void sel(int total) {// 减少权重
        current.addAndGet(-1 * total);
    }
    public long getLastUpdate() {
        return lastUpdate;
    }
    public void setLastUpdate(long lastUpdate) {
        this.lastUpdate = lastUpdate;
    }
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

`最不活跃`的负载均衡策略

```java
// 1. 统计索引invoker 的调用次数 active
// 2. 如果存在 active 次数相同的 Invoker 那么就根据权重进行随机
protected <T> Invoker<T> doSelect(List<Invoker<T>> invokers, URL url, Invocation invocation) {
    // Number of invokers
    int length = invokers.size();
    // The least active value of all invokers
    int leastActive = -1;
    // The number of invokers having the same least active value (leastActive)
    int leastCount = 0;
    // The index of invokers having the same least active value (leastActive)
    int[] leastIndexes = new int[length];
    // the weight of every invokers
    int[] weights = new int[length];
    // The sum of the warmup weights of all the least active invokes
    int totalWeight = 0;
    // The weight of the first least active invoke
    int firstWeight = 0;
    // Every least active invoker has the same weight value?
    boolean sameWeight = true;
    // Filter out all the least active invokers
    // 下面的for找到一个active 最小的 ivoker
    // 如果存在两个相等的 invoker
    // 那么放入数组中，进行跟进权重，继续随机
    for (int i = 0; i < length; i++) {
        Invoker<T> invoker = invokers.get(i);
        // Get the active number of the invoke active= 方法执行的次数
        int active = RpcStatus.getStatus(invoker.getUrl(), invocation.getMethodName()).getActive();
        // Get the weight of the invoke configuration. The default value is 100.
        int afterWarmup = getWeight(invoker, invocation);
        // save for later use
        weights[i] = afterWarmup;
        // If it is the first invoker or the active number of the invoker is less than the current least active number
        if (leastActive == -1 || active < leastActive) {
            // Reset the active number of the current invoker to the least active number
            leastActive = active;
            // Reset the number of least active invokers
            leastCount = 1;
            // Put the first least active invoker first in leastIndexes
            leastIndexes[0] = i;
            // Reset totalWeight
            totalWeight = afterWarmup;
            // Record the weight the first least active invoker
            firstWeight = afterWarmup;
            // Each invoke has the same weight (only one invoker here)
            sameWeight = true;
            // If current invoker's active value equals with leaseActive, then accumulating.
        } else if (active == leastActive) {// 存在调试次数相同的 Invoker
            // Record the index of the least active invoker in leastIndexes order
            leastIndexes[leastCount++] = i;// 放入数组中，后续进行权重随机使用
            // Accumulate the total weight of the least active invoker
            totalWeight += afterWarmup;
            // If every invoker has the same weight?
            if (sameWeight && i > 0
                    && afterWarmup != firstWeight) {
                sameWeight = false;
            }
        }
    }
    // Choose an invoker from all the least active invokers
    if (leastCount == 1) {// 没有 active 相同的
        // If we got exactly one invoker having the least active value, return this invoker directly.
        return invokers.get(leastIndexes[0]);
    }
    if (!sameWeight && totalWeight > 0) {
        // If (not every invoker has the same weight & at least one invoker's weight>0), select randomly based on 
        // totalWeight.
        int offsetWeight = ThreadLocalRandom.current().nextInt(totalWeight);
        // Return a invoker based on the random value.
        for (int i = 0; i < leastCount; i++) {
            int leastIndex = leastIndexes[i];
            offsetWeight -= weights[leastIndex];
            if (offsetWeight < 0) {
                return invokers.get(leastIndex);
            }
        }
    }
    // If all invokers have the same weight value or totalWeight=0, return evenly.
    return invokers.get(leastIndexes[ThreadLocalRandom.current().nextInt(leastCount)]);
}
```