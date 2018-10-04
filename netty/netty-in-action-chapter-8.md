# CHAPTER 8

This chapter covers
- Bootstrapping clients and servers
- Bootstrapping clients from within a Channel
- Adding ChannelHandlers
- Using ChannelOptions and attributes

![Bootstrap](./images/Bootstrap.png)

## Bootstrap class

```java
public abstract class AbstractBootstrap
<B extends AbstractBootstrap<B,C>,C extends Channel>
{

}

public class Bootstrap
extends AbstractBootstrap<Bootstrap,Channel>
{

}

public class ServerBootstrap
extends AbstractBootstrap<ServerBootstrap,ServerChannel>
{

}
```

## Bootstrapping a client

```java
{
        EventLoopGroup group = new NioEventLoopGroup();
        Bootstrap bootstrap = new Bootstrap();
        bootstrap.group(group)
            .channel(NioSocketChannel.class)
            .handler(new SimpleChannelInboundHandler<ByteBuf>() {
                @Override
                protected void channelRead0(
                    ChannelHandlerContext channelHandlerContext,
                    ByteBuf byteBuf) throws Exception {
                    System.out.println("Received data");
                }
                });
        ChannelFuture future =
            bootstrap.connect(
                    new InetSocketAddress("www.manning.com", 80));
        future.addListener(new ChannelFutureListener() {
            @Override
            public void operationComplete(ChannelFuture channelFuture)
                throws Exception {
                if (channelFuture.isSuccess()) {
                    System.out.println("Connection established");
                } else {
                    System.err.println("Connection attempt failed");
                    channelFuture.cause().printStackTrace();
                }
            }
        });
}
```
## IllegalStateException

More on IllegalStateException When bootstrapping, before you call `bind()` or `connect()` you must call the following
methods to set up the required components.
- group()
- channel() or channnelFactory()
- handler()

Failure to do so will cause an IllegalStateException. The handler() call is particularly
important because it’s needed to configure the ChannelPipeline.

## Bootstrapping servers

```java
{
        NioEventLoopGroup group = new NioEventLoopGroup();
        ServerBootstrap bootstrap = new ServerBootstrap();
        bootstrap.group(group)
            .channel(NioServerSocketChannel.class)
            .childHandler(new SimpleChannelInboundHandler<ByteBuf>() {
                @Override
                protected void channelRead0(ChannelHandlerContext channelHandlerContext,
                    ByteBuf byteBuf) throws Exception {
                    System.out.println("Received data");
                }
            });
        ChannelFuture future = bootstrap.bind(new InetSocketAddress(8080));
        future.addListener(new ChannelFutureListener() {
            @Override
            public void operationComplete(ChannelFuture channelFuture)
                throws Exception {
                if (channelFuture.isSuccess()) {
                    System.out.println("Server bound");
                } else {
                    System.err.println("Bind attempt failed");
                    channelFuture.cause().printStackTrace();
                }
            }
        });
    }
```

## Bootstrapping clients from a Channel