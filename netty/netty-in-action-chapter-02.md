# CHAPTER 2

## ChannelHandler

At least one  ChannelHandler —This component implements the server’s processing of data received from the client—its business logic

## ChannelInboundHandlerAdapter

## Bootstrapping

Bootstrapping This is the startup code that configures the server. At a minimum,
it binds the server to the port on which it will listen for connection requests.

1. Bind to the port on which the server will listen for and accept incoming connection requests
2. Configure  Channels to notify an  `EchoServerHandler` instance about inbound messages

## Service

## Client