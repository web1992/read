# Channel

## NioServerSocketChannel

从下面几点了解`NioServerSocketChannel`

1. [创建实例](#创建实例)
2. [open ServerSocketChannel](#open)
3. [unsafe 和 pipeline 的初始化](#unsafe和pipeline的初始化)
4. [设置为非阻塞模式](#设置为非阻塞模式)
5. [绑定 Selector](#绑定Selector)
6. [绑定 Socket](#绑定Socket)

> 上面的步骤在 java Nio 中是`同步`的代码调用，而在 Netty 中，进行了`异步`的处理,把 5,6 步骤放到了 taskQueue,让 NioEventLoop 进行处理
> 同时也会把注册事件放入到 pipeline 中进行流处理(比如你可以注册一个 ChannelHandler 对注册事件进行特殊的处理)

![NioServerSocketChannel](./images/NioServerSocketChannel.png)

### 创建实例

`AbstractBootstrap#initAndRegister`

```java
    // 利用反射进行初始化
    // 这里是一个无参的构造方法
    channel = channelFactory.newChannel();
    init(channel);
```

### open ServerSocketChannel

`NioServerSocketChannel#newSocket`

```java
    private static ServerSocketChannel newSocket(SelectorProvider provider) {
        try {
            /**
             *  Use the {@link SelectorProvider} to open {@link SocketChannel} and so remove condition in
             *  {@link SelectorProvider#provider()} which is called by each ServerSocketChannel.open() otherwise.
             *
             *  See <a href="https://github.com/netty/netty/issues/2308">#2308</a>.
             */
             // 通过 SelectorProvider 来打开一个Channel
             // provider 一个静态变量，为了提升性能
            return provider.openServerSocketChannel();
        } catch (IOException e) {
            throw new ChannelException(
                    "Failed to open a server socket.", e);
        }
    }
```

## 设置为非阻塞模式

`AbstractNioChannel#AbstractNioChannel`

```java
    protected AbstractNioChannel(Channel parent, SelectableChannel ch, int readInterestOp) {
        super(parent);
        this.ch = ch;
        this.readInterestOp = readInterestOp;
        try {
            ch.configureBlocking(false);
        } catch (IOException e) {
            try {
                ch.close();
            } catch (IOException e2) {
                if (logger.isWarnEnabled()) {
                    logger.warn(
                            "Failed to close a partially initialized socket.", e2);
                }
            }

            throw new ChannelException("Failed to enter non-blocking mode.", e);
        }
    }
```

## unsafe 和 pipeline 的初始化

`AbstractChannel#AbstractChannel`

Channel 在初始化的时候，会进行`unsafe`和`pipeline`的初始化,代码如下:

```java
    protected AbstractChannel(Channel parent) {
        this.parent = parent;
        id = newId();
        unsafe = newUnsafe();
        pipeline = newChannelPipeline();
    }
```

## 绑定 Selector

`AbstractNioChannel#doRegister`

这个过程是异步的,这个绑定`Selector`事件是通过 pipeline 提交给 EventLoop 进行绑定的

最终的实现代码如下：

```java
    @Override
    protected void doRegister() throws Exception {
        boolean selected = false;
        for (;;) {
            try {
                // 第一个参数： Selector与channel进行绑定
                // 第二个参数： 这里经典的做法是设置为 SelectionKey#OP_ACCEPT, 但是这里设置为0
                // Netty是在AbstractNioChannel#doBeginRead 进行了绑定,可看下面的解释
                // 第三个参数： 把 this就是NioServerSocketChannel当做附件进行绑定，方便后续使用
                selectionKey = javaChannel().register(eventLoop().unwrappedSelector(), 0, this);
                return;
            } catch (CancelledKeyException e) {
                if (!selected) {
                    // Force the Selector to select now as the "canceled" SelectionKey may still be
                    // cached and not removed because no Select.select(..) operation was called yet.
                    eventLoop().selectNow();
                    selected = true;
                } else {
                    // We forced a select operation on the selector before but the SelectionKey is still cached
                    // for whatever reason. JDK bug ?
                    throw e;
                }
            }
        }
    }

    // AbstractNioChannel#doBeginRead
    @Override
    protected void doBeginRead() throws Exception {
        // Channel.read() or ChannelHandlerContext.read() was called
        final SelectionKey selectionKey = this.selectionKey;
        if (!selectionKey.isValid()) {
            return;
        }

        readPending = true;

        final int interestOps = selectionKey.interestOps();
        // interestOps 其实就是 javaChannel().register(eventLoop().unwrappedSelector(), 0, this); 0这个参数
        // readInterestOp 其实就是SelectionKey#OP_ACCEPT(readInterestOp在AbstractNioChannel的构造方法中进行的初始化)
        // 这里进行检查如果插入的事件是0，那么就进行OP_ACCEPT的注册
        if ((interestOps & readInterestOp) == 0) {
            selectionKey.interestOps(interestOps | readInterestOp);
        }
    }
```

### 绑定 Socket

`NioServerSocketChannel#doBind`

这个过程是异步的,这个绑定`Socket`事件是通过 pipeline 提交给 EventLoop 进行绑定的

最终的实现代码如下：

```java
    @Override
    protected void doBind(SocketAddress localAddress) throws Exception {
        if (PlatformDependent.javaVersion() >= 7) {
            javaChannel().bind(localAddress, config.getBacklog());
        } else {
            javaChannel().socket().bind(localAddress, config.getBacklog());
        }
    }
```
