# MessageQueue

- `MessageQueue` 封装了 topic，brokerName，queueId 信息
- `MessageQueue` 是在 consumer 消费端进行重平衡之后分配到的queue的信息。

```java
// MessageQueue 的定义
public class MessageQueue implements Comparable<MessageQueue>, Serializable {
    private static final long serialVersionUID = 6191200464116433425L;
    private String topic;
    private String brokerName;
    private int queueId;

    public MessageQueue() {

    }
    // ...
}
```

`MessageQueue` 是在 consumer 消费端进行重平衡之后分配到的queue的信息,下面是具体的代码例子:

```java
// org.apache.rocketmq.client.impl.consumer.RebalanceImpl#updateProcessQueueTableInRebalance
// updateProcessQueueTableInRebalance 此方法就是 重平衡 之后调用的方法
private boolean updateProcessQueueTableInRebalance(final String topic, final Set<MessageQueue> mqSet,
        final boolean isOrder) {
        // ...
        // 循环处理分配的 MessageQueue
        // 创建 PullRequest， ProcessQueue 。
        // 把 MessageQueue+ProcessQueue 设置PullRequest的属性 放入到队列中
        for (MessageQueue mq : mqSet) {
            if (!this.processQueueTable.containsKey(mq)) {
                if (isOrder && !this.lock(mq)) {
                    log.warn("doRebalance, {}, add a new mq failed, {}, because lock failed", consumerGroup, mq);
                    continue;
                }

                this.removeDirtyOffset(mq);
                ProcessQueue pq = new ProcessQueue();
                long nextOffset = this.computePullFromWhere(mq);
                if (nextOffset >= 0) {
                    ProcessQueue pre = this.processQueueTable.putIfAbsent(mq, pq);
                    if (pre != null) {
                        log.info("doRebalance, {}, mq already exists, {}", consumerGroup, mq);
                    } else {
                        log.info("doRebalance, {}, add a new mq, {}", consumerGroup, mq);
                        PullRequest pullRequest = new PullRequest();
                        pullRequest.setConsumerGroup(consumerGroup);
                        pullRequest.setNextOffset(nextOffset);
                        pullRequest.setMessageQueue(mq);
                        pullRequest.setProcessQueue(pq);
                        pullRequestList.add(pullRequest);
                        changed = true;
                    }
                } else {
                    log.warn("doRebalance, {}, add new mq failed, {}", consumerGroup, mq);
                }
            }
        }

        //  把  PullRequest 任务放入到 PullMessageService 的 pullRequestQueue 队列，有线程异步的进行消息的拉取
        this.dispatchPullRequest(pullRequestList);
}
```

```java
// PullMessageService 继承了ServiceThread
public class PullMessageService extends ServiceThread {
    private final LinkedBlockingQueue<PullRequest> pullRequestQueue = new LinkedBlockingQueue<PullRequest>();


    // 这个是异步的线程任务
    public void run() {
        log.info(this.getServiceName() + " service started");

        while (!this.isStopped()) {
            try {
                PullRequest pullRequest = this.pullRequestQueue.take();
                this.pullMessage(pullRequest);
            } catch (InterruptedException ignored) {
            } catch (Exception e) {
                log.error("Pull Message Service Run Method exception", e);
            }
        }

        log.info(this.getServiceName() + " service end");
    }
}
```

从上面可以，consumer 端，为每一个分配的 MessageQueue 都会创建一个 PullRequest ，进行消息的拉取。

关于 ProcessQueue 的作用可以参考下面这个文章：

- [ProcessQueue](rocketmq-process-queue.md)
- [MessageQueue](rocketmq-message-queue.md)

如果理解了 `ProcessQueue`和`MessageQueue` 的作用，那么在看 PullRequest 的定义，就很清晰了。

```java
// org.apache.rocketmq.client.impl.consumer.PullRequest
public class PullRequest {
    private String consumerGroup;
    private MessageQueue messageQueue;
    private ProcessQueue processQueue;
    private long nextOffset;
    private boolean lockedFirst = false;
}
```

`MessageQueue` 是消费端分配到的 queue 信息，`ProcessQueue` 是维护了拉取的消息和一些统计信息。

这样线程在从队列中，拿到`PullRequest`之后就可以决定是否继续拉去消息，还是`歇一会`。
