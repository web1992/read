# MessageExt

MessageExtBrokerInner

## MessageExt 的序列化

`MessageExt` 的序列化，从 `Producer` 创建的`Msg`是如何存储的在文件中的,

除了 `Msg` 的 `Body`，`Topic`，`Tags` 等信息，还存储了那些额外的信息？已经存储这些额外信息的作用。

## 先上图

以 `MessageExtBrokerInner` 为例,消息的存储格式:

![rocket-store-msg.png](images/rocket-store-msg.png)
