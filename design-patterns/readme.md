# Design Patterns

## 设计模式本质

解耦和重用

1. 软件中的设计模式，是设计优秀可维护软件的基础。使用好的设计模式，设计出来的软件系统，更方便维护。
2. 理解了每个设计模式的含义和应用场景，是通向架构师的必经之路。
3. 大多框架都是使用大量的设计模式，对于阅读理解这些代码设计也大有帮助。

- 设计模式三个准则：
  - 1 中意于组合而不是继承
  - 2 依赖于接口而不是实现
  - 3 高内聚，低耦合

## 设计理念

- [云原生的设计理念](https://jimmysong.io/kubernetes-handbook/cloud-native/cloud-native-philosophy.html)

下面的设计理念来自上面的 `云原生的设计理念`,在日常的软件开发中可以有所应用。

面向分布式设计（Distribution）：容器、微服务、API 驱动的开发；
面向配置设计（Configuration）：一个镜像，多个环境配置；
面向韧性设计（Resistancy）：故障容忍和自愈；
面向弹性设计（Elasticity）：弹性扩展和对环境变化（负载）做出响应；
面向交付设计（Delivery）：自动拉起，缩短交付时间；
面向性能设计（Performance）：响应式，并发和资源高效利用；
面向自动化设计（Automation）：自动化的 DevOps；
面向诊断性设计（Diagnosability）：集群级别的日志、metric 和追踪；
面向安全性设计（Security）：安全端点、API Gateway、端到端加密；

## 分类总结

下面的图片是来自 `wiki` 的图片。并对设计模式进行了分类

- Gang of Four patterns
- Concurrency patterns
- Architectural patterns
- Other patterns

![design pattern](./images/design-pattern.png)

| 分 类             | 描 述     |
| ----------------- | --------- |
| Creational        | 创造      |
| Structural        | 结构      |
| Behavioral        | 行为      |
| Functional        | 实用      |
| Concurrency       | 并发      |
| Architectural     | 建筑      |
| Cloud Distributed | 云 分布式 |

## 列表

- [Observer Pattern](observer-pattern.md)
- [State Pattern](state-pattern.md)
- [Strategy pattern(Policy Pattern)](strategy-pattern.md)
- [Reactor Pattern](reactor-pattern.md)
- [Template method pattern](template-method-pattern.md)
- [Decorator pattern](decorator-pattern.md)
- [Chain-of-responsibility pattern](chain-of-responsibility-pattern.md)

## 模型

- [线程模型](https://my.oschina.net/u/1024107/blog/752025)
- [Reactor 线程模型](https://blog.csdn.net/u013074465/article/details/46276967)

## link

- [设计模式](https://en.wikipedia.org/wiki/Software_design_pattern)
- [Design Patterns](https://en.wikipedia.org/wiki/Design_Patterns)
