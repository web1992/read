# Chain-of-responsibility pattern

> 责任链模式,23种设计模式之一

- [https://en.wikipedia.org/wiki/Chain-of-responsibility_pattern](https://en.wikipedia.org/wiki/Chain-of-responsibility_pattern)
- [与装饰器模式类似](decorator-pattern.md)

## What problems can the Chain of Responsibility design pattern solve

- Coupling the sender of a request to its receiver should be avoided.
- It should be possible that more than one receiver can handle a request.

## What solution does the Chain of Responsibility design pattern describe

- Define a chain of receiver objects having the responsibility, depending on run-time conditions, to either handle a request or forward it to the next receiver on the chain (if any).

## 实例

- [dubbo-channel-handler.md](../dubbo/dubbo-channel-handler.md)