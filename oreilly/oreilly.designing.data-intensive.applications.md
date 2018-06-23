# Reilly.Designing.Data-Intensive.Applications

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
