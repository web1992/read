# Observer Pattern

- [Observer Pattern](https://en.wikipedia.org/wiki/Observer_pattern)

23 种设计模式之一

## What problems can the Observer design pattern solve

- A one-to-many dependency between objects should be defined without making the objects tightly coupled.
- It should be ensured that when one object changes state an open-ended number of dependent objects are updated automatically.
- It should be possible that one object can notify an open-ended number of other objects.

## What solution does the Observer design pattern describe

- Define Subject and Observer objects.
- so that when a subject changes state,all registered observers are notified and updated automatically.