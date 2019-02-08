# CHAPTER 2

This chapter covers

- Setting up the development environment
- Writing an Echo server and client
- Building and testing the applications

All Netty servers require the following:

- At least one ChannelHandler This component implements the server’s processing of data received from the client—its business logic.

- Bootstrapping This is the startup code that configures the server. At a minimum,it binds the server to the port on which it will listen for connection requests.In the remainder of this section we’ll describe the logic and bootstrapping code for the Echo server.

## ChannelHandler

At least one ChannelHandler This component implements the server’s processing of data received from the client—its business logic

## ChannelInboundHandlerAdapter

## SimpleChannelInboundHandler

`SimpleChannelInboundHandler` vs. `ChannelInboundHandler`
You may be wondering why we used `SimpleChannelInboundHandler` in the client instead of the `ChannelInboundHandlerAdapter` used in the `EchoServerHandler`.

This has to do with the interaction of two factors: how the business logic processes messages and how Netty manages resources.

In the client, when channelRead0() completes, you have the incoming message and you’re done with it. When the method returns, `SimpleChannelInboundHandler` takes care of `releasing` the memory reference to the ByteBuf that holds the message.

In EchoServerHandler you still have to echo the incoming message to the sender, and the write() operation, which is asynchronous, may not complete until after channelRead() returns (shown in listing 2.1). For this reason `EchoServerHandler` extends `ChannelInboundHandlerAdapter`, which doesn’t release the message at this point.

The message is released in `channelReadComplete`() in the EchoServerHandler when `writeAndFlush()` is called (listing 2.1).

## Service

The following steps are required in bootstrapping:

- Create a ServerBootstrap instance to bootstrap and bind the server.
- Create and assign an NioEventLoopGroup instance to handle event processing,such as accepting new connections and reading/writing data.
- Specify the local InetSocketAddress to which the server binds.
- Initialize each new Channel with an EchoServerHandler instance.
- Call ServerBootstrap.bind() to bind the server.

## Client

- A Bootstrap instance is created to initialize the client.
- An NioEventLoopGroup instance is assigned to handle the event processing,which includes creating new connections and processing inbound and outbound data.
- An InetSocketAddress is created for the connection to the server.
- An EchoClientHandler will be installed in the pipeline when the connection is established.
- After everything is set up, Bootstrap.connect() is called to connect to the remote peer.
