# Reilly.Designing.Data-Intensive.Applications

## Who Should Read This Book

- You want to learn how to make data systems scalable, for example, to support web or mobile apps with millions of users.
- You need to make applications highly available (minimizing downtime) and operationally robust.
- You are looking for ways of making systems easier to maintain in the long run,even as they grow and as requirements and technologies change.
- You have a natural curiosity for the way things work and want to know what goes on inside major websites and online services. This book breaks down the internals of various databases and data processing syste

## The Unix Philosophy

> A Unix shell like bash lets us easily compose these small programs into surprisingly
> powerful data processing jobs. Even though many of these programs are written by
> different groups of people, they can be joined together in flexible ways. What does
> Unix do to enable this composability?

- A uniform interface
- Separation of logic and wiring

## Relational Versus Document Databases Today

There are many differences to consider when comparing relational databases to
document databases, including their fault-tolerance properties (see Chapter 5) and
handling of concurrency (see Chapter 7). In this chapter, we will concentrate only on
the differences in the data model.

The main arguments in favor of the document data model are schema flexibility, bet‐
ter performance due to locality, and that for some applications it is closer to the data
structures used by the application. The relational model counters by providing better
support for joins, and many-to-one and many-to-many relationships.

## stream processing

### Acknowledgments and redelivery

Consumers may crash at any time, so it could happen that a broker delivers a mes‐
sage to a consumer but the consumer never processes it, or only partially processes it
before crashing. In order to ensure that the message is not lost, message brokers use
acknowledgments: a client must explicitly tell the broker when it has finished process‐
ing a message so that the broker can remove it from the queue.
If the connection to a client is closed or times out without the broker receiving an
acknowledgment, it assumes that the message was not processed, and therefore it
delivers the message again to another consumer. (Note that it could happen that the
message actually was fully processed, but the acknowledgment was lost in the net‐
work. Handling this case requires an atomic commit