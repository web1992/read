# CHAPTER 7

This chapter covers:

- Threading model overview
- Event loop concept and implementation
- Task scheduling
- Implementation details

## Threading model overview

Pooling and reusing threads is an improvement over creating and destroying a thread
with each task, but it doesn’t `eliminate`(消除) the cost of context switching, which quickly
becomes apparent as the number of threads increases and can be severe under heavy
load. In addition, other thread-related problems can arise during the lifetime of a project
simply because of the overall complexity or concurrency requirements of an application.
In short, multithreading can be complex. In the next sections we’ll see how Netty
helps to simplify it.

## EventLoop

The basic idea of an event loop is illustrated in the following listing, where each
task is an instance of Runnable

```java
while (!terminated) {
    List<Runnable> readyEvents = blockUntilEventsReady();
    for (Runnable ev: readyEvents) {
        ev.run();
    }
}
```

![EventLoop](./images/Interface-EventLoop.png)

## Scheduling tasks using EventLoop

Occasionally you’ll need to schedule a task for later (deferred) or periodic execution.
For example, you might want to register a task to be fired after a client has been
connected for five minutes. A common use case is to send a heartbeat message to a
remote peer to check whether the connection is still alive. If there is no response, you
know you can close the channel.
In the next sections, we’ll show you how to schedule tasks with both the core Java
API and Netty’s EventLoop . Then, we’ll examine the internals of Netty’s
implementation and discuss its advantages and limitations.

## Thread management

## EventLoop/thread allocation
