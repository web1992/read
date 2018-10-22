# State Pattern

- [from wiki](https://en.wikipedia.org/wiki/State_pattern)

23 种设计模式之一

The state pattern is a behavioral software design pattern to allow an object to alter its behavior when its internal state changes.

当状态变化的时候，引起行为的变化。（这个状态对调用着无感知）

The state pattern can be interpreted as a strategy pattern which is able to switch the current strategy through invocations of methods defined in the pattern's interface.

可以与策略模式做对比，通过不同的状态变化，在不同的策略之间进行转化，从而改变起行为。

What problems can the State design pattern solve?

- An object should change its behavior when its internal state changes.
- State-specific behavior should be defined independently. That is, new states should be added and the behavior of existing states should be changed independently.

状态模式解决的问题

- 当状态改变的时候，行为发生改变
- 状态必须是独立的。当新增状态的时候，已存在的状态必须单独的改变。
