# Chapter 12

Advanced client options

This chapter covers

- How to use exclusive consumers
- The power of message groups
- Understanding support for streams and blobs
- The failover transport
- Scheduling message delivery

In the last chapter we covered advanced ActiveMQ broker features. In this chapter
we’re going to look at some advanced features on the client side of ActiveMQ. We’ll
look at how to ensure that one message consumer will receive messages from a
queue, regardless of how many message consumers have subscribed to it. This feature
is called exclusive consumer, and can be used for ensuring that messages are
always consumed in order, or as a distributed locking mechanism—for which we
have an example. We’ll look at message groups, where messages can be grouped
together to be consumed by the same message consumer. ActiveMQ supports two
different ways to send large payloads through ActiveMQ—using ActiveMQ streams
and blob messages—and we’ll look at both methods. As the client-side failover
transport protocol is important for applications to survive network outages and
broker failure, we’ll look at its nuances in more detail. And, finally, we’ll look at
sending messages with a delay, and delay using scheduled messages.