# Bootstrap and ServerBootstrap

关键字：

- Bootstrap
- ServerBootstrap
- NioSocketChannel
- NioServerSocketChannel
- ChannelInitializer
- ChannelOption
- ChannelHandler
- ChannelFuture
- EventLoop
- EventLoopGroup
- EventLoopGroup bossGroup
- EventLoopGroup workerGroup

关键字说明

| 类                         | 描述                         |
| -------------------------- | ---------------------------- |
| Bootstrap                  | 客户端启动类                 |
| ServerBootstrap            | 服务端启动类                 |
| NioSocketChannel           | 客户端 Channel               |
| NioServerSocketChannel     | 服务端的 Channel             |
| ChannelInitializer         | 添加 ChannelHandler 的辅助类 |
| ChannelOption              | TCP 选项                     |
| ChannelHandler             | 处理自己业务的 Handler       |
| ChannelFuture              | 操作 Channel 的工具类        |
| EventLoop                  |
| EventLoopGroup             |
| EventLoopGroup bossGroup   |
| EventLoopGroup workerGroup |

- [Bootstrap and ServerBootstrap](#bootstrap-and-serverbootstrap)
  - [ServerBootstrap](#serverbootstrap)
    - [EventLoopGroup init](#eventloopgroup-init)
    - [channelFactory](#channelfactory)
    - [init](#init)
  - [bind](#bind)
    - [Channel init](#channel-init)
    - [SocketAddress bind](#socketaddress-bind)
  - [childHandler](#childhandler)
  - [Bootstrap](#bootstrap)
    - [group](#group)
    - [channel](#channel)
    - [handler](#handler)
    - [connect](#connect)
    - [Resolve](#resolve)

## ServerBootstrap

服务器 `ServerBootstrap` 初始化过程

类的继承关系

![ServerBootstrap](./images/ServerBootstrap.png)

下面从这几点来分析：

1. [init group](#初始化-group)
2. [init channelFactory](#channelFactory)
3. [init](#init)
4. [bind](#bind)

### EventLoopGroup init

`EventLoopGroup` 是 `Netty` 中线程模型的实现 `EventLoopGroup` 包含了多个 `NioEventLoop`

`EventLoopGroup` 提供了 `next` 方法，方便按照轮询的方式从一组 `NioEventLoop` 中选择一个 `NioEventLoop` 去处理 `IO` 事件

> 可以把 `NioEventLoop` 理解为 `Thread` 把 `EventLoopGroup` 理解成 `Thread[]` 数组

```java
// parentGroup for server
// childGroup for client
public ServerBootstrap group(EventLoopGroup parentGroup, EventLoopGroup childGroup) {
        super.group(parentGroup);
        if (childGroup == null) {
            throw new NullPointerException("childGroup");
        }
        if (this.childGroup != null) {
            throw new IllegalStateException("childGroup set already");
        }
        this.childGroup = childGroup;
        return this;
    }
```

`ServerBootstrap`的构造方法有两个参数`parentGroup`,`childGroup`

EventLoopGroup 本质是维护了一组 EventLoop，并提供了 `next` 方法，在这些 EventLoop
中选择一个(轮询的方式) EventLoop 进行事件的处理,具体的实现可以查看`io.netty.util.concurrent.DefaultEventExecutorChooserFactory`

- parentGroup 负责处理服务当前所有服务器 Channel 的事件
- childGroup 负责处理连接到当前服务器 channel 的客户端的 Channel 事件

childGroup 当做参数给了 ServerBootstrapAcceptor，ServerBootstrapAcceptor 重写了`channelRead`
方法，用 childGroup.register 方法来绑定客户端的 channel 与 childGroup 中的 EventLoop
具体细节可以参照[这里](source-code-channel.md#ServerBootstrapAcceptor)

### channelFactory

```java
// ReflectiveChannelFactory
@Override
public T newChannel() {
    try {
        // 这里使用反射进行实例化
        return clazz.newInstance();
    } catch (Throwable t) {
        throw new ChannelException("Unable to create Channel from class " + clazz, t);
    }
}
```

### init

```java
// 获取到pipeline
ChannelPipeline p = channel.pipeline();
// 注册 initChannel 事件，这个事件在其他渠道注册的时候会发生
// 比如客户端连接到服务器的时候
p.addLast(new ChannelInitializer<Channel>() {
    @Override
    public void initChannel(final Channel ch) throws Exception {
        final ChannelPipeline pipeline = ch.pipeline();
        ChannelHandler handler = config.handler();
        if (handler != null) {
            pipeline.addLast(handler);
        }
        ch.eventLoop().execute(new Runnable() {
            @Override
            public void run() {
                pipeline.addLast(new ServerBootstrapAcceptor(
                        ch, currentChildGroup, currentChildHandler, currentChildOptions, currentChildAttrs));
            }
        });
    }
});
```

## bind

`bind` 方法调用如下：

```java
ChannelFuture future = bootstrap.bind(new InetSocketAddress(8081));
```

bind 主要有两个步骤：第一个执行 `Channel` 的初始化 第二个是执行 `SocketAddress` 的绑定。

### Channel init

`Channel` 的初始的代码如下：

```java
// ServerBootstrap -> init
// ServerBootstrapAcceptor 主要是执行 childHandler 的初始化
// 而 childHandler 一般是用来实现用户的自定义的逻辑的
// 可以看下面的 childHandler 的介绍
p.addLast(new ChannelInitializer<Channel>() {
    @Override
    public void initChannel(final Channel ch) throws Exception {
        final ChannelPipeline pipeline = ch.pipeline();
        ChannelHandler handler = config.handler();
        if (handler != null) {
            pipeline.addLast(handler);
        }
        ch.eventLoop().execute(new Runnable() {
            @Override
            public void run() {
                // 在 pipeline 中添加 ServerBootstrapAcceptor
                pipeline.addLast(new ServerBootstrapAcceptor(
                        ch, currentChildGroup, currentChildHandler, currentChildOptions, currentChildAttrs));
            }
        });
    }
});
```

### SocketAddress bind

把 `Channel` 绑定到 `SocketAddress` 地址

```java
// 这里把注册事件，通过 pipeline 进行异步的注册
private static void doBind0(
            final ChannelFuture regFuture, final Channel channel,
            final SocketAddress localAddress, final ChannelPromise promise) {

        // This method is invoked before channelRegistered() is triggered.  Give user handlers a chance to set up
        // the pipeline in its channelRegistered() implementation.
        channel.eventLoop().execute(new Runnable() {
            @Override
            public void run() {
                if (regFuture.isSuccess()) {
                    channel.bind(localAddress, promise).addListener(ChannelFutureListener.CLOSE_ON_FAILURE);
                } else {
                    promise.setFailure(regFuture.cause());
                }
            }
        });
    }
```

## childHandler

`childHandler` 这个在`ServerBootstrap`中是必须设置的，相当自定义 `pipeline` 的组装入口

`childHandler` 在组装 `bootstrap` 的时候被调用如下:

```java
bootstrap.group(group).channel(NioServerSocketChannel.class).childHandler(new ChannelInitializerImpl());
```

而 `ChannelInitializerImpl` 则是在 `channelRead` 事件发生的时候才会被加入到 `pipeline` 中的,代码如下:

```java
// ServerBootstrap -> ServerBootstrapAcceptor -> channelRead
child.pipeline().addLast(childHandler);
```

一个经典的 ChannelInitializerImpl 实现如下：

```java
/**
 * ChannelInitializerImpl 可以实现自己的 pipeline 的组装
 */
final class ChannelInitializerImpl extends ChannelInitializer<Channel> {
    @Override
    protected void initChannel(Channel ch) throws Exception {
        ChannelPipeline pipeline = ch.pipeline();
        // ObjectDecoder 负责把 byte 转化成 java 对象
        pipeline.addLast(new ObjectDecoder(new MyClassResolver()));
        // NettyHandler 处理业务逻辑
        pipeline.addLast(new NettyHandler());
    }
}
```

## Bootstrap

客户端`Bootstrap`初始化过程

### group

这里的 group 同样也管理这一组`EventLoop`,`Bootstrap`少了`childGroup`这个参数，
因为`Bootstrap`是连接到服务器的，不需要用另一个 Group 线程组，来管理来自客户端的连接.

### channel

`NioSocketChannel` 这个最终也会被`EventLoop`进行关联,这个过程与`ServerBootstrap`的初始化一样

### handler

`handler` 用来用户方便添加自己的 `pipeline`

```java
bootstrap.group(group).channel(NioSocketChannel.class).handler(new ChannelInitializerImpl());
```

```java
/**
 * 实现自定义的 pipeline 的组装
 */
final class ChannelInitializerImpl extends ChannelInitializer<Channel> {
    @Override
    protected void initChannel(Channel ch) throws Exception {
        ChannelPipeline pipeline = ch.pipeline();
        pipeline.addLast(new ObjectEncoder());
        //pipeline.addLast(new ClazzToByteEncoder());
    }
}
```

### connect

连接到指定的 IP 地址

### Resolve

负责 `DNS` 解析
