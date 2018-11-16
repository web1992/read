# Bootstrap and ServerBootstrap

## ServerBootstrap

服务器`ServerBootstrap`初始化过程

类的继承关系

![ServerBootstrap](./images/ServerBootstrap.png)

下面从这几点来分析：

1. [初始化-group](#初始化-group)
2. [初始化 channelFactory](#channelFactory)
3. [init](#init)
4. [bind](#bind)

### 初始化-group

```java
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
        // 注册initChannel事件，这个事件在其他渠道注册的时候会发生
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

把打开的 channel 绑定到 SocketAddress 地址

```java
// 这里把注册事件，通过pipeline 进行异步的注册
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

## Bootstrap

客户端`Bootstrap`初始化过程
