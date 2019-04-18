# zookeeper

- [zookeeper](#zookeeper)
  - [uml](#uml)
  - [zookeeper info](#zookeeper-info)
    - [provider start](#provider-start)
    - [consumer start](#consumer-start)
  - [AbstractRegistry](#abstractregistry)
  - [FailbackRegistry](#failbackregistry)
  - [ZookeeperRegistry](#zookeeperregistry)
    - [doRegister](#doregister)
    - [doUnregister](#dounregister)
    - [doSubscribe](#dosubscribe)
    - [doUnsubscribe](#dounsubscribe)

## uml

![ZookeeperRegistry](images/dubbo-registry-zookeeper.png)

## zookeeper info

这里通过`zkCli.sh(cmd)` 和`zkServer.sh(cmd)` 查看下在 `dubbo` 的 `provider` 和 `customer` 启动之后，

zk 节点下面的数据变化，有一个直观的感受

### provider start

```sh
# 在 provider 启动之后执行
ls /dubbo

# cn.web1992.dubbo.demo.DemoService

ls /dubbo/cn.web1992.dubbo.demo.DemoService

# configurators, consumers, providers, routers

ls /dubbo/cn.web1992.dubbo.demo.DemoService/providers

# output

# dubbo%3A%2F%2F10.108.3.7%3A20880%2Fcn.web1992.dubbo.demo.DemoService%3Fanyhost%
# 3Dtrue%26application%3Ddemo-provider%26bean.name%3Dcn.web1992.dubbo.demo.DemoSer
# vice%26default.deprecated%3Dfalse%26default.dynamic%3Dfalse%26default.register%3
# Dtrue%26deprecated%3Dfalse%26dubbo%3D2.0.2%26dynamic%3Dfalse%26generic%3Dfalse%2
# 6interface%3Dcn.web1992.dubbo.demo.DemoService%26methods%3DsayHello%2Cdemo%26pid
# %3D21776%26register%3Dtrue%26release%3D2.7.1%26side%3Dprovider%26timestamp%3D155
# 5554643022

# url decode 之后

# dubbo://10.108.3.7:20880/cn.web1992.dubbo.demo.DemoService?anyhost=true
# &application=demo-provider
# &bean.name=cn.web1992.dubbo.demo.DemoService
# &default.deprecated=false
# &default.dynamic=false
# &default.register=true
# &deprecated=false
# &dubbo=2.0.2
# &dynamic=false
# &generic=false
# &interface=cn.web1992.dubbo.demo.DemoService
# &methods=sayHello,demo
# &pid=21776
# &register=true
# &release=2.7.1
# &side=provider
# &timestamp=1555554643022

```

`zk` 的 `providers` 会把 `dubbo` 相关的信息接口信息，如：`cn.web1992.dubbo.demo.DemoService`

接口中的方法: `methods=sayHello,demo` 等存储在 `providers` 数据节点中

### consumer start

```sh

# 在 consumer 启动后的信息
ls /dubbo/cn.web1992.dubbo.demo.DemoService/consumers

# output

# consumer%3A%2F%2F10.108.3.7%2Fcn.web1992.dubbo.demo.DemoService%3Fapplication%3
# Ddemo-consumer%26category%3Dconsumers%26check%3Dfalse%26default.lazy%3Dfalse%26d
# efault.sticky%3Dfalse%26dubbo%3D2.0.2%26interface%3Dcn.web1992.dubbo.demo.DemoSe
# rvice%26lazy%3Dfalse%26methods%3DsayHello%2Cdemo%26pid%3D27220%26qos.port%3D3333
# 3%26release%3D2.7.1%26retries%3D0%26side%3Dconsumer%26sticky%3Dfalse%26timestamp
# %3D1555490957945

# url decode 之后

# consumer://10.108.3.7/cn.web1992.dubbo.demo.DemoService?application=demo-consumer
# &category=consumers
# &check=false
# &default.lazy=false
# &default.sticky=false
# &dubbo=2.0.2
# &interface=cn.web1992.dubbo.demo.DemoService
# &lazy=false
# &methods=sayHello,demo
# &pid=27220
# &qos.port=33333
# &release=2.7.1
# &retries=0
# &side=consumer
# &sticky=false
# &timestamp=1555490957945

## 在 consumer 正常关闭之后，执行

ls /dubbo/cn.web1992.dubbo.demo.DemoService/consumers

# output
#[]

```

## AbstractRegistry

`AbstractRegistry` 抽象类，根据名字就可以知道，这个类提供一下通用方法的实现

比如当 `provider` 信息变化的时候 `customer` 会把这些信息存储在文件中，启动的时候，也会从文件中读取这些洗洗

文件内容如下：

```properties
key = "cn.web1992.dubbo.demo.DemoService"

value = "empty://10.108.3.7/cn.web1992.dubbo.demo.DemoService?application=demo-consumer&category=routers&check=false&default.lazy=false&default.sticky=false&dubbo=2.0.2&interface=cn.web1992.dubbo.demo.DemoService&lazy=false&methods=sayHello,demo&pid=20856&qos.port=33333&release=2.7.1&retries=0&side=consumer&sticky=false&timestamp=1555556670429 empty://10.108.3.7/cn.web1992.dubbo.demo.DemoService?application=demo-consumer&category=configurators&check=false&default.lazy=false&default.sticky=false&dubbo=2.0.2&interface=cn.web1992.dubbo.demo.DemoService&lazy=false&methods=sayHello,demo&pid=20856&qos.port=33333&release=2.7.1&retries=0&side=consumer&sticky=false&timestamp=1555556670429"
```

## FailbackRegistry

```java
// 模板方法
public abstract void doRegister(URL url);
public abstract void doUnregister(URL url);
public abstract void doSubscribe(URL url, NotifyListener listener);
public abstract void doUnsubscribe(URL url, NotifyListener listener);
```

`FailbackRegistry` 提供了注册失败的重试机制

`abstract` 方法,子类实现这些抽象方法，完成注册，订阅逻辑，在发生异常的时候

被 `FailbackRegistry`捕获,他会创建定时任务，执行注册任务

```java
// FailbackRegistry
// 注册失败的定时任务
private void addFailedRegistered(URL url) {
    FailedRegisteredTask oldOne = failedRegistered.get(url);
    if (oldOne != null) {
        return;
    }
    FailedRegisteredTask newTask = new FailedRegisteredTask(url, this);
    oldOne = failedRegistered.putIfAbsent(url, newTask);
    if (oldOne == null) {
        // never has a retry task. then start a new task for retry.
        retryTimer.newTimeout(newTask, retryPeriod, TimeUnit.MILLISECONDS);
    }
}
```

## ZookeeperRegistry

`ZookeeperRegistry` 是 `dubbo` 以 `zk` 作为注册中心的具体实现类

### doRegister

```java
// ZookeeperRegistry
// 注册：根据 url  创建 zk 节点
@Override
public void doRegister(URL url) {
    try {
        zkClient.create(toUrlPath(url), url.getParameter(Constants.DYNAMIC_KEY, true));
    } catch (Throwable e) {
        throw new RpcException("Failed to register " + url + " to zookeeper " + getUrl() + ", cause: " + e.getMessage(), e);
    }
}
```

当 `customer` 注册的时候 `toUrlPath(url)` 信息如下:

![dubbo-customer-registry](images/dubbo-customer-registry.png)

### doUnregister

```java
// ZookeeperRegistry
// 取消注册： 根据 url  删除 zk 节点
@Override
public void doUnregister(URL url) {
    try {
        zkClient.delete(toUrlPath(url));
    } catch (Throwable e) {
        throw new RpcException("Failed to unregister " + url + " to zookeeper " + getUrl() + ", cause: " + e.getMessage(), e);
    }
}
```

### doSubscribe

```java
// ZookeeperRegistry
// 订阅
@Override
public void doSubscribe(final URL url, final NotifyListener listener) {
    try {
        // 省略代码...
        } else {
            List<URL> urls = new ArrayList<>();
            // 以 customer 端订阅为例：
            // toCategoriesPath 会根据 URL 创建下面的三种节点
            // 并分别进行监听
            // 0 = "/dubbo/cn.web1992.dubbo.demo.DemoService/providers"
            // 1 = "/dubbo/cn.web1992.dubbo.demo.DemoService/configurators"
            // 2 = "/dubbo/cn.web1992.dubbo.demo.DemoService/routers"
            for (String path : toCategoriesPath(url)) {
                ConcurrentMap<NotifyListener, ChildListener> listeners = zkListeners.get(url);
                if (listeners == null) {
                    zkListeners.putIfAbsent(url, new ConcurrentHashMap<>());
                    listeners = zkListeners.get(url);
                }
                ChildListener zkListener = listeners.get(listener);
                if (zkListener == null) {
                    listeners.putIfAbsent(listener, (parentPath, currentChilds) -> ZookeeperRegistry.this.notify(url, listener, toUrlsWithEmpty(url, parentPath, currentChilds)));
                    zkListener = listeners.get(listener);
                }
                // 创建节点
                // 这里说下 create 创建节点的时候，如果节点已经存在，会直接返回
                zkClient.create(path, false);
                // 设置监听
                List<String> children = zkClient.addChildListener(path, zkListener);
                if (children != null) {
                    urls.addAll(toUrlsWithEmpty(url, path, children));
                }
            }
            notify(url, listener, urls);
        }
    } catch (Throwable e) {
        throw new RpcException("Failed to subscribe " + url + " to zookeeper " + getUrl() + ", cause: " + e.getMessage(), e);
    }
}
```

### doUnsubscribe

```java
// ZookeeperRegistry
// 取消订阅
// 根据Url 查询 NotifyListener，然后进行删除
@Override
public void doUnsubscribe(URL url, NotifyListener listener) {
    ConcurrentMap<NotifyListener, ChildListener> listeners = zkListeners.get(url);
    if (listeners != null) {
        ChildListener zkListener = listeners.get(listener);
        if (zkListener != null) {
            if (Constants.ANY_VALUE.equals(url.getServiceInterface())) {
                String root = toRootPath();
                zkClient.removeChildListener(root, zkListener);
            } else {
                for (String path : toCategoriesPath(url)) {
                    zkClient.removeChildListener(path, zkListener);
                }
            }
        }
    }
}
```