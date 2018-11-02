# ChannelPipeline

## DefaultChannelPipeline

`DefaultChannelPipeline`的初始化

Channle 在初始化的时候，会进行`unsafe`和`pipeline`的初始化,代码如下:

```java
    protected AbstractChannel(Channel parent) {
        this.parent = parent;
        id = newId();
        unsafe = newUnsafe();
        pipeline = newChannelPipeline();
    }
```

读事件触发的代码:

```java
   @Override
    public final ChannelPipeline fireChannelRead(Object msg) {
        // head 代表这个`pipeline`链中的第一个，进行读事件的流转
        // msg 是已经读取的原始数据(byte数据)
        AbstractChannelHandlerContext.invokeChannelRead(head, msg);
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

`AbstractChannelHandlerContext#invokeChannelRead`

```java
    private void invokeChannelRead(Object msg) {
        if (invokeHandler()) {
            try {
                ((ChannelInboundHandler) handler()).channelRead(this, msg);
            } catch (Throwable t) {
                notifyHandlerException(t);
            }
        } else {
            fireChannelRead(msg);
        }
    }
```

`AbstractChannelHandlerContext#fireChannelRead`

```java
    @Override
    public ChannelHandlerContext fireChannelRead(final Object msg) {
        // findContextInbound() 这个方法从head 开始找下一个context
        invokeChannelRead(findContextInbound(), msg);
        return this;
    }
```

## 读事件的流程

1. 首页要明确，读事件是从`NioEventLoop#processSelectedKey`触发的(`NioEventLoop`负责所有读写事件的转发)
2. 然后这个事件被转发到`AbstractNioChannel.NioUnsafe`这个类
3. 而`AbstractNioChannel` -> `AbstractNioChannel` -> `AbstractChannel` 这个三个类的继承,因此可以在`AbstractNioChannel`中获取`pipeline`,`pipeline`开始进行事件的转发
4. `pipeline`从链头部，开始进行读事件的处理

pipeline -> AbstractChannelHandlerContext(head) -> ChannelHandler -> HeadContext -> AbstractChannelHandlerContext -> findContextInbound -> AbstractChannelHandlerContext(head.next)
