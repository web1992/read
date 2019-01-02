# Chapter 05

ActiveMQ message storage

This chapter covers

- How messages are stored in ActiveMQ for both queues and topics
- The four styles of message stores provided with ActiveMQ
- How ActiveMQ caches messages for consumers
- How to control message caching using subscription recovery policies

## How are messages stored by ActiveMQ

Messages sent to queues and topics are stored differently, because there are some storage
optimizations that can be made with topics that don’t make sense with queues, as we’ll explain.

Storage for queues is straightforward—messages are basically stored in first in, first out order (FIFO). One message is dispatched to a
single consumer at a time. Only when that message has been consumed and acknowledged
can it be deleted from the broker’s message store.

| queue                                        | topic                                        |
| -------------------------------------------- | -------------------------------------------- |
| ![active-queue](./images/activemq-queue.png) | ![active-topic](./images/activemq-topic.png) |

## The KahaDB message store

The recommended message store for general-purpose messages since ActiveMQ version
5.3 is KahaDB. This is a file-based message store that combines a transactional journal(交易日记),
for reliable message storage and recovery, with good performance and scalability.

> config

```xml
<broker brokerName="broker" persistent="true" useShutdownHook="false">
...
<persistenceAdapter>
<kahaDB directory="activemq-data" journalMaxFileLength="16mb"/>
</persistenceAdapter>
...
</broker>
```

## The AMQ message store internals

## The JDBC message store

But the use of a shared database is particularly useful for making a redundant master/
slave topology out of multiple brokers. When a group of ActiveMQ brokers is configured
to use a shared database, they’ll all try to connect and grab a lock in the lock
table, but only one will succeed and become the master. The remaining brokers will
be slaves, and will be in a wait state, not accepting client connections until the master
fails. This is a common deployment scenario for ActiveMQ, which will be covered in
more detail in chapter 10.

- Apache Derby
- MySQL
- PostgreSQL
- Oracle
- SQL Server
- Sybase
- Informix
- MaxDB

## The JDBC message store schema

The JDBC message store uses a schema consisting of `three` tables. Two of the tables are
used to hold messages, and the third is used as a `lock table` to ensure that only one
ActiveMQ broker can access the database at one time. Here’s a detailed breakdown of
these tables.

- `ACTIVEMQ_MSGS`
- `ACTIVEMQ_ACKS`
- `CTIVEMQ_LOCK`

The message table.Messages are broken down and stored into the `ACTIVEMQ_MSGS` table for both
queues and topics.

The columns of the `ACTIVEMQ_MSGS` SQL table

| Column     | name         | Default type Description                                                                                           |
| ---------- | ------------ | ------------------------------------------------------------------------------------------------------------------ |
| ID         | INTEGER      | The sequence ID used to retrieve the message.                                                                      |
| CONTAINER  | VARCHAR(250) | The destination of the message.                                                                                    |
| MSGID_PROD | VARCHAR(250) | The ID of the message producer.                                                                                    |
| MSGID_SEQ  | INTEGER      | The producer sequence number for the message. This together with the MSGID_PROD is equivalent to the JMSMessageID. |
| EXPIRATION | BIGINT       | The time in milliseconds when the message will expire.                                                             |
| MSG        | BLOB         | The serialized message itself.                                                                                     |

There’s a separate table for holding durable subscriber information and an ID to
the last message the durable subscriber received.

The columns of the `ACTIVEMQ_ACKS` SQL table

| Column        | name         | Default type Description                                                                           |
| ------------- | ------------ | -------------------------------------------------------------------------------------------------- |
| CONTAINER     | VARCHAR(250) | The destination of the message                                                                     |
| SUB_DEST      | VARCHAR(250) | The destination of the durable subscriber (can be different from the container if using wildcards) |
| CLIENT_ID     | VARCHAR(250) | The client ID of the durable subscriber                                                            |
| SUB_NAME      | VARCHAR(250) | The subscriber name of the durable subscriber                                                      |
| SELECTOR      | VARCHAR(250) | The selector of the durable subscriber                                                             |
| LAST_ACKED_ID | Integer      | The sequence ID of last message received by this subscriber                                        |

For durable subscribers, the `LAST_ACKED_ID` sequence is used as a simple pointer into
the `ACTIVEMQ_MSGS` and enables messages for a particular durable subscriber to be
easily selected from the `ACTIVEMQ_MSGS` table.

The lock table, called `ACTIVEMQ_LOCK`, is used to ensure that only one ActiveMQ
broker instance can access the database at one time. If an ActiveMQ broker can’t grab
the database lock, that broker won’t initialize fully, and will wait until the lock
becomes free, or it’s shut down.

The columns of the `ACTIVEMQ_LOCK` SQL table

| Column | name    | Default type Description                                       |
| ------ | ------- | -------------------------------------------------------------- |
| ID     | INTEGER | A unique ID for the lock                                       |
| Broker | Name    | VARCHAR(250) The name of the ActiveMQ broker that has the lock |

## Configuring the JDBC message store

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans>
<broker brokerName="test-broker" persistent="true" xmlns="http://activemq.apache.org/schema/core">
<persistenceAdapter>
    <jdbcPersistenceAdapter dataSource="#mysql-ds"/>
</persistenceAdapter>
</broker>
<bean id="mysql-ds"
    class="org.apache.commons.dbcp.BasicDataSource" destroy-method="close">
    <property name="driverClassName" value="com.mysql.jdbc.Driver"/>
    <property name="url" value="jdbc:mysql://localhost/activemq?relaxAutoCommit=true"/>
    <property name="username" value="activemq"/>
    <property name="password" value="activemq"/>
    <property name="maxActive" value="200"/>
    <property name="poolPreparedStatements" value="true"/>
    </bean>
</beans>
```

## Using the JDBC message store with the ActiveMQ journal

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans>
<broker brokerName="test-broker"
xmlns="http://activemq.apache.org/schema/core">
<persistenceFactory>
<journalPersistenceAdapterFactory
journalLogFiles="4"
journalLogFileSize="32768"
useJournal="true"
useQuickJournal="true"
dataSource="#derby-ds"
dataDirectory="activemq-data" />
</persistenceFactory>
</broker>
<bean id="derby-ds" class="org.apache.derby.jdbc.EmbeddedDataSource">
<property name="databaseName" value="derbydb"/>
<property name="createDatabase" value="create"/>
</bean>
</beans>
```

## The memory message store

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans>
<broker brokerName="test-broker"
persistent="false"
xmlns="http://activemq.apache.org/schema/core">
<transportConnectors>
<transportConnector uri="tcp://localhost:61635"/>
</transportConnectors>
</broker>
</beans>
```

Embedding an ActiveMQ broker with the memory store is easy. The following
example starts a broker with the memory store:

```java
import org.apache.activemq.broker.BrokerService;
public void createEmbeddedBroker() throws Exception {
    BrokerService broker = new BrokerService();
    //configure the broker to use the Memory Store
    broker.setPersistent(false);
    //Add a transport connector
    broker.addConnector("tcp://localhost:61616");
    //now start the broker
    broker.start();
}
```