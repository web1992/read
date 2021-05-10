# rebalance

RocketMQ 中重平衡的实现逻辑。重平衡的主要目的是实现多个`Consumer`之间负载均衡。在`Consumer`上线和下线的时候，都会触发重平衡。

重平衡的主要类是 `RebalanceImpl`

## doRebalance

```java
// doRebalance 核心方法
public void doRebalance(final boolean isOrder) {
    Map<String, SubscriptionData> subTable = this.getSubscriptionInner();
    if (subTable != null) {
        for (final Map.Entry<String, SubscriptionData> entry : subTable.entrySet()) {
            final String topic = entry.getKey();
            try {
                this.rebalanceByTopic(topic, isOrder);
            } catch (Throwable e) {
                if (!topic.startsWith(MixAll.RETRY_GROUP_TOPIC_PREFIX)) {
                    log.warn("rebalanceByTopic Exception", e);
                }
            }
        }
    }
    this.truncateMessageQueueNotMyTopic();
}
```

## rebalanceByTopic

下面是执行`重平衡`的核心逻辑

```java
private void rebalanceByTopic(final String topic, final boolean isOrder) {
    switch (messageModel) {
        case BROADCASTING: {
            // ...
            break;
        }
        case CLUSTERING: {
            // 获取 MessageQueue 列表(mqSet)和所有的Consume(cidAll)列表
            Set<MessageQueue> mqSet = this.topicSubscribeInfoTable.get(topic);
            List<String> cidAll = this.mQClientFactory.findConsumerIdList(topic, consumerGroup);
           
            if (mqSet != null && cidAll != null) {
                List<MessageQueue> mqAll = new ArrayList<MessageQueue>();
                mqAll.addAll(mqSet);
                // 排序，十分主要
                Collections.sort(mqAll);
                Collections.sort(cidAll);
                // 获取分配策略
                AllocateMessageQueueStrategy strategy = this.allocateMessageQueueStrategy;
                List<MessageQueue> allocateResult = null;
                // 按照分配策略，给每个Consumer分配MessageQueue
                allocateResult = strategy.allocate(
                    this.consumerGroup,
                    this.mQClientFactory.getClientId(),
                    mqAll,
                    cidAll);
                Set<MessageQueue> allocateResultSet = new HashSet<MessageQueue>();
                if (allocateResult != null) {
                    allocateResultSet.addAll(allocateResult);
                }
                // 更新 ProcessQueue
                boolean changed = this.updateProcessQueueTableInRebalance(topic, allocateResultSet, isOrder);
                if (changed) {
                    // 
                    this.messageQueueChanged(topic, mqSet, allocateResultSet);
                }
            }
            break;
        }
        default:
            break;
    }
}
```
