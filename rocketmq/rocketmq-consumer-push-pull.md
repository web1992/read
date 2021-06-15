# RocketMQ PUSH and PULL

## ConsumeType

这里先看下ConsumeType，分为两种`PULL`和`PUSH`，因此Consumer消费消息主要有两种模式。

```java
public enum ConsumeType {

    CONSUME_ACTIVELY("PULL"),

    CONSUME_PASSIVELY("PUSH");

    private String typeCN;

    ConsumeType(String typeCN) {
        this.typeCN = typeCN;
    }

    public String getTypeCN() {
        return typeCN;
    }
}

```

## RebalanceImpl

`RebalanceImpl` 有3种实现。

- RebalanceLitePullImpl
- RebalancePullImpl
- RebalancePushImpl

`RebalanceImpl` 的抽象方法

| 方法                          | 描述                                                                       |
| ----------------------------- | -------------------------------------------------------------------------- |
| messageQueueChanged           | 处理Queue变化(比如Consumer上下线，重平衡触发)                              |
| removeUnnecessaryMessageQueue | 也是在重平衡触发之后，做移除queue的操作                                    |
| consumeType                   | `ConsumeType` 目前有 `PULL` 和 `PUSH`                                      |
| removeDirtyOffset             | 移除对 consumer offset 的管理                                              |
| computePullFromWhere          | 拉取消费开始的位置                                                         |
| dispatchPullRequest           | 转发 `PullRequest` 请求，主要针对 `RebalancePushImpl` 实现。其他是空实现。 |
