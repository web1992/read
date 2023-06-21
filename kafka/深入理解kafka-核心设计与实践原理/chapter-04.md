# 第4章 主题与分区

- KafkaAdminClient
- TopicCommand
- CreateTopicsRequest、DeleteTopicsRequest
- auto.create.topics.enable 不建议打开(自动创建的主题，行为不符合预期)
-  

## 主题与分区

主题和分区是Kafka 的两个核心概念，前面章节中讲述的生产者和消费者的设计理念所针对的都是主题和分区层面的操作。主题作为消息的归类，可以再细分为一个或多个分区，分区也可以看作对消息的二次归类。分区的划分不仅为Kafka提供了可伸缩性、水平扩展的功能，还通过多副本机制来为Kafka提供数据冗余以提高数据可靠性。

