# RocketMQ tags

## Message tag 的存储

消息的 tag 是存在 `Property` 中的，代码如下：

```java
public void setTags(String tags) {
    this.putProperty(MessageConst.PROPERTY_TAGS, tags);
}
```

看图：![rocket-store-msg.png](./images/rocket-store-msg.png)

## Message 消费tag过滤

先说结论：tag 的过滤是通过 `MessageFilter` 在`Broker`完成的。

tag 的使用方式：

```java
// 忽略tag
consumer.subscribe("TopicTest", "*");
// 关注特定的tag
consumer.subscribe("TopicTest", "tag1 || tag2 || tag3");
```

转成 `SubscriptionData`。

```java
// SubscriptionData
public final static String SUB_ALL = "*";
private boolean classFilterMode = false;
private String topic;
private String subString;
private Set<String> tagsSet = new HashSet<String>();
private Set<Integer> codeSet = new HashSet<Integer>();
private long subVersion = System.currentTimeMillis();
private String expressionType = ExpressionType.TAG;
```

`PullMessageRequestHeader`

`tag` 信息最终会被转化成 `PullMessageRequestHeader` 的 `subscription` 字段，传输到`Borker`

```java
// PullMessageRequestHeader 代码片段
@CFNullable
private String subscription;
@CFNotNull
private Long subVersion;
private String expressionType;
```

`Borker` 使用 `MessageFilter#isMatchedByConsumeQueue` 进行消息的过滤。

## DefaultMessageStore#getMessage

`DefaultMessageStore#getMessage` 是查询消息的核心实现。
