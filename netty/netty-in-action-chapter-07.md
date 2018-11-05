# CHAPTER 7

This chapter covers:

- Threading model overview
- Event loop concept and implementation
- Task scheduling
- Implementation details

## EventLoop

## Scheduling tasks using EventLoop

Occasionally you’ll need to schedule a task for later (deferred) or periodic execution.
For example, you might want to register a task to be fired after a client has been con-
nected for five minutes. A common use case is to send a heartbeat message to a
remote peer to check whether the connection is still alive. If there is no response, you
know you can close the channel.
In the next sections, we’ll show you how to schedule tasks with both the core Java
API and Netty’s  EventLoop . Then, we’ll examine the internals of Netty’s implementa-
tion and discuss its advantages and limitations.

## Thread management

## EventLoop/thread allocation