# CHAPTER 2

This chapter covers

- Setting up the development environment
- Writing an Echo server and client
- Building and testing the applications

All Netty servers require the following:

- At least one ChannelHandler—This component implements the server’s processing
of data received from the client—its business logic.

- Bootstrapping—This is the startup code that configures the server. At a minimum,
it binds the server to the port on which it will listen for connection requests.
In the remainder of this section we’ll describe the logic and bootstrapping code for
the Echo server.

## ChannelHandler

At least one ChannelHandler —This component implements the server’s processing of data received from the client—its business logic

## ChannelInboundHandlerAdapter

## Bootstrapping

Bootstrapping This is the startup code that configures the server. At a minimum,
it binds the server to the port on which it will listen for connection requests.

1. Bind to the port on which the server will listen for and accept incoming connection requests
2. Configure Channels to notify an `EchoServerHandler` instance about inbound messages

## Service

## Client
