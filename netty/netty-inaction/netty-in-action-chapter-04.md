# CHAPTER 4

This chapter covers

- OIO blocking transport
- NIO asynchronous transport
- Local transport asynchronous communications within a JVM
- Embedded transport testing your ChannelHandlers

- [CHAPTER 4](#chapter-4)
  - [ChannelHandlers](#channelhandlers)
  - [Channel methods](#channel-methods)
  - [Netty-provided transports](#netty-provided-transports)
  - [Optimal transport for an application](#optimal-transport-for-an-application)
  - [NIO—non-blocking I/O](#nionon-blocking-io)
  - [Selection operation bit-set](#selection-operation-bit-set)

## ChannelHandlers

Typical uses for ChannelHandlers include:

- Transforming data from one format to another
- Providing notification of exceptions
- Providing notification of a Channel becoming active or inactive
- Providing notification when a Channel is registered with or deregistered from an EventLoop
- Providing notification about user-defined events

## Channel methods

| Method        | name Description                                                                                                                                                                                                                                |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| eventLoop     | Returns the EventLoop that is assigned to the Channel.                                                                                                                                                                                          |
| pipeline      | Returns the ChannelPipeline that is assigned to the Channel.                                                                                                                                                                                    |
| isActive      | Returns true if the Channel is active. The meaning of active may depend on the underlying transport. For example, a Socket transport is active once connected to the remote peer, whereas a Datagram transport would be active once it’s open. |
| localAddress  | Returns the local SocketAddress.                                                                                                                                                                                                                |
| remoteAddress | Returns the remote SocketAddress.                                                                                                                                                                                                               |
| write         | Writes data to the remote peer. This data is passed to the ChannelPipeline and queued until it’s flushed.                                                                                                                                      |
| flush         | Flushes the previously written data to the underlying transport, such as a Socket.                                                                                                                                                              |
| writeAndFlush | A convenience method for calling write() followed by flush().                                                                                                                                                                                   |

## Netty-provided transports

| Name     | Package                     | Description                                                                                                                                                                                  |
| -------- | --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| NIO      | io.netty.channel.socket.nio | Uses the java.nio.channels package as a foundation—a selector-based approach.                                                                                                               |
| Epoll    | io.netty.channel.epoll      | Uses JNI for epoll() and non-blocking IO.This transport supports features available only on Linux, such as SO_REUSEPORT, and is faster than the NIO transport as well as fully non-blocking. |
| OIO      | io.netty.channel.socket.oio | Uses the java.net package as a foundationuses blocking streams.                                                                                                                              |
| Local    | io.netty.channel.local      | A local transport that can be used to communicate in the VM via pipes.                                                                                                                       |
| Embedded | io.netty.channel.embedded   | An embedded transport, which allows using ChannelHandlers without a true network- based transport. This can be quite useful for testing your ChannelHandler implementations.                 |

## Optimal transport for an application

| Application needs                                | Recommended transport   |
| ------------------------------------------------ | ----------------------- |
| Non-blocking code base or general starting point | NIO (or epoll on Linux) |
| Blocking code base                               | OIO                     |
| Communication within the same                    | JVM Local               |
| Testing ChannelHandler implementations           | Embedded                |

## NIO—non-blocking I/O

The basic concept behind the selector is to serve as a registry where you request to be notified when the state of a Channel changes. The possible state changes are

- A new Channel was accepted and is ready.
- A Channel connection was completed.
- A Channel has data that is ready for reading.
- A Channel is available for writing data.

## Selection operation bit-set

| Name       | Description                                                                                                                                                                                                                              |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OP_ACCEPT  | Requests notification when a new connection is accepted, and a Channel is created.                                                                                                                                                       |
| OP_CONNECT | Requests notification when a connection is established.                                                                                                                                                                                  |
| OP_READ    | Requests notification when data is ready to be read from the Channel.                                                                                                                                                                    |
| OP_WRITE   | Requests notification when it is possible to write more data to the Channel. Thishandles cases when the socket buffer is completely filled, which usually happens when data is transmitted more rapidly than the remote peer can handle. |
