# ChannelPipeline

这里介绍下面几个点：

1. `ChannelPipeline` 什么时候初始化
2. 如何进行进行`流处理`

## 预处理

读事件的流程触发点

1. 首页要明确，读事件是从`NioEventLoop#processSelectedKey`触发的(`NioEventLoop`负责所有读写事件的转发)
2. 然后这个事件被转发到`AbstractNioChannel.NioUnsafe`这个类
3. 而`AbstractNioChannel` -> `AbstractNioChannel` -> `AbstractChannel` 这个三个类存在继承关系,因此可以在`AbstractNioChannel`中获取`pipeline`,`pipeline`开始进行事件的转发
4. `pipeline`从链头部(`HeadContext`)，开始进行读事件的处理
5. 进入自定义的 ChannelHandler,如`SimpleChannelInboundHandler`

## 源码分析

默认实现 `DefaultChannelPipeline`

`DefaultChannelPipeline`的初始化

Channel 在初始化的时候，会进行`unsafe`和`pipeline`的初始化,代码如下:

```java
    protected AbstractChannel(Channel parent) {
        this.parent = parent;
        id = newId();
        unsafe = newUnsafe();
        pipeline = newChannelPipeline();
    }
```

读事件触发的代码:

`DefaultChannelPipeline#fireChannelRead`

```java
    @Override
    public final ChannelPipeline fireChannelRead(Object msg) {
        // head 代表这个pipeline链中的第一个，进行读事件的流转
        // head 就是HeadContext
        // msg 是已经读取的原始数据(byte数据)
        AbstractChannelHandlerContext.invokeChannelRead(this.head, msg);
        return this;
    }
```

而`head`是在`DefaultChannelPipeline`初始化的时候生成的,代码如下:

```java
    protected DefaultChannelPipeline(Channel channel) {
        this.channel = ObjectUtil.checkNotNull(channel, "channel");
        succeededFuture = new SucceededChannelFuture(channel, null);
        voidPromise =  new VoidChannelPromise(channel, true);

        tail = new TailContext(this);
        head = new HeadContext(this);

        head.next = tail;
        tail.prev = head;
    }
```

因此`head`是`HeadContext`

`AbstractChannelHandlerContext#invokeChannelRead` // 1⃣️

```java
    private void invokeChannelRead(Object msg) {
        if (invokeHandler()) {
            try {
                // 这里的 this 就是 HeadContext
                // 当下次在调这个方法的时候，这个 this 会指向 HeadContext.next
                // 比如 SimpleChannelInboundHandler
                ((ChannelInboundHandler) handler()).channelRead(this, msg);
            } catch (Throwable t) {
                notifyHandlerException(t);
            }
        } else {
            fireChannelRead(msg);
        }
    }
```

`HeadContext`

```java
        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
            // 这里 HeadContext 什么都不做，只是把 msg 传递到下个handler
            ctx.fireChannelRead(msg);
        }
```

`AbstractChannelHandlerContext#fireChannelRead` // 2⃣️

```java
    @Override
    public ChannelHandlerContext fireChannelRead(final Object msg) {
        // findContextInbound() 这个方法从head 开始找下一个context
        // 比如找到了 SimpleChannelInboundHandler
        invokeChannelRead(findContextInbound(), msg);
        return this;
    }

    private AbstractChannelHandlerContext findContextInbound() {
        AbstractChannelHandlerContext ctx = this;
        do {
            ctx = ctx.next;
        } while (!ctx.inbound);
        return ctx;
    }
```

这里来看`SimpleChannelInboundHandler`的处理

`SimpleChannelInboundHandler#channelRead` // 3⃣️

```java
    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        boolean release = true;
        try {
            if (acceptInboundMessage(msg)) {
                @SuppressWarnings("unchecked")
                I imsg = (I) msg;
                channelRead0(ctx, imsg);
            } else {
                // false 不释放msg,把这个msg 给其他handler处理
                release = false;
                // 这里把这个 msg 传递给下一个ChannelHandler
                // 会调用 AbstractChannelHandlerContext#fireChannelRead 找到下一个handler
                // findContextInbound 找到下一个handler 回到了2⃣️步骤
                ctx.fireChannelRead(msg);
            }
        } finally {
            if (autoRelease && release) {
                ReferenceCountUtil.release(msg);
            }
        }
    }
```
