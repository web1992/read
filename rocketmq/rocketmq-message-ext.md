# MessageExt

RocketMQ  如何存储（持久化）消息

## MessageExt 的序列化存储

`MessageExt` 的序列化存储，从 `Producer` 创建的`Msg`，会被 borker 包装成 `MessageExt` 对象 本文分析 `MessageExt` 是如何存储的在文件中的,

除了 `Msg` 的 `Body`，`Topic`，`Tags` 等信息，还存储了那些额外的信息？以及存储这些额外信息的作用。

## 先上图

以 `MessageExtBrokerInner` 为例,消息的存储格式:

![rocket-store-msg.png](./images/rocket-store-msg.png)

上图是根据 `org.apache.rocketmq.store.CommitLog` 中内部类 `DefaultAppendMessageCallback` 源码绘制。
