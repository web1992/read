# CHAPTER 4

netty's transport

## Transport API

Typical uses for ChannelHandlers include:

- ■ Transforming data from one format to another
- ■ Providing notification of exceptions
- ■ Providing notification of a Channel becoming active or inactive
- ■ Providing notification when a Channel is registered with or deregistered from an EventLoop
- ■ Providing notification about user-defined events

## Netty-provided transports

Name    | Package | Description
----    | --------| ------------
NIO     | io.netty.channel.socket.nio |  Uses the java.nio.channels package as a foundation—a selector-based approach.
Epoll   | io.netty.channel.epoll      |  Uses JNI for epoll() and non-blocking IO.This transport supports features available only on Linux, such as SO_REUSEPORT, and is faster than the NIO transport as well as fully non-blocking.
OIO     | io.netty.channel.socket.oio | Uses the java.net package as a foundationuses blocking streams.
Local   | io.netty.channel.local      | A local transport that can be used to communicate in the VM via pipes.
Embedded| io.netty.channel.embedded   | An embedded transport, which allows using ChannelHandlers without a true network- based transport. This can be quite useful for testing your ChannelHandler implementations.

## Optimal transport for an application

Application needs | Recommended transport
----------------- | ---------------------
Non-blocking code base or general starting point | NIO (or epoll on Linux)
Blocking code base | OIO
Communication within the same | JVM Local
Testing ChannelHandler implementations |Embedded
