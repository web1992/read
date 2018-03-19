# JMS (Java Message Service)

- 1 [introduction](#introduction)
- 2 [jmstemplate](#jmstemplate)
- 3 [connections](#connections)
- 4 [caching-messaging-resources](#caching-messaging-resources)
- 5 [destination-management](#destination-management)
- 6 [transaction-management](#transaction-management)
- 7 [sending-a-message](#sending-a-message)
- 8 [using-message-converters](#using-message-converters)
- 9 [receiving-a-message](#receiving-a-message)
- 10 [synchronous-reception](#synchronous-reception)
- 11 [asynchronous-reception-message-driven-pojos](#asynchronous-reception-message-driven-pojos)
- 12 [sessionawaremessagelistener-interface](#sessionawaremessagelistener-interface)
- 13 [messagelisteneradapter](#messagelisteneradapter)
- 14 [processing-messages-within-transactions](#processing-messages-within-transactions)
- 15 [support-for-jca-message-endpoints](#support-for-jca-message-endpoints)
- 16 [jms-namespace-support](#jms-namespace-support)

## Introduction

JMS can be roughly divided into two areas of functionality, namely the production and consumption of messages. The JmsTemplate class is used for message production and synchronous message reception. For asynchronous reception similar to Java EE’s message-driven bean style, Spring provides a number of message listener containers that are used to create Message-Driven POJOs (MDPs). Spring also provides a declarative way of creating message listeners.

The classes offer various convenience methods for the sending of messages, consuming a message synchronously, and exposing the JMS session and message producer to the user.

## JmsTemplate

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#jms-using)

## Connections

ConnectionFactory
SingleConnectionFactory
CachingConnectionFactory

### Caching Messaging Resources

ConnectionFactory->Connection->Session->MessageProducer->send

## Destination Management

## Transaction management

## Sending a Message

The JmsTemplate contains many convenience methods to send a message. There are send methods that specify the destination using a javax.jms.Destination object and those that specify the destination using a string for use in a JNDI lookup. The send method that takes no destination argument uses the default destination.

```java
import javax.jms.ConnectionFactory;
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.Queue;
import javax.jms.Session;

import org.springframework.jms.core.MessageCreator;
import org.springframework.jms.core.JmsTemplate;

public class JmsQueueSender {

    private JmsTemplate jmsTemplate;
    private Queue queue;

    public void setConnectionFactory(ConnectionFactory cf) {
        this.jmsTemplate = new JmsTemplate(cf);
    }

    public void setQueue(Queue queue) {
        this.queue = queue;
    }

    public void simpleSend() {
        this.jmsTemplate.send(this.queue, new MessageCreator() {
            public Message createMessage(Session session) throws JMSException {
                return session.createTextMessage("hello queue world");
            }
        });
    }
}
```

## Using Message Converters

`MapMessageConverter`
`SimpleMessageConverter`
`TextMessage`
`BytesMesssage`
`MessagePostProcessor`

To accommodate the setting of a message’s properties, headers, and body that can not be generically encapsulated inside a converter class, the MessagePostProcessor interface gives you access to the message after it has been converted, but before it is sent. The example below demonstrates how to modify a message header and a property after a java.util.Map is converted to a message.

```java
public void sendWithConversion() {
    Map map = new HashMap();
    map.put("Name", "Mark");
    map.put("Age", new Integer(47));
    jmsTemplate.convertAndSend("testQueue", map, new MessagePostProcessor() {
        public Message postProcessMessage(Message message) throws JMSException {
            message.setIntProperty("AccountID", 1234);
            message.setJMSCorrelationID("123-00001");
            return message;
        }
    });
}
```

This results in a message of the form:

```json
MapMessage={
	Header={
		... standard headers ...
		CorrelationID={123-00001}
	}
	Properties={
		AccountID={Integer:1234}
	}
	Fields={
		Name={String:Mark}
		Age={Integer:47}
	}
}
```

## Receiving a message

### Synchronous reception

While JMS is typically associated with asynchronous processing, it is possible to consume messages synchronously. The overloaded receive(..) methods provide this functionality. During a synchronous receive, `the calling thread blocks until a message becomes available`. This can be a dangerous operation since the calling thread can potentially be blocked indefinitely. The property receiveTimeout specifies how long the receiver should wait before giving up waiting for a message.

### Asynchronous reception Message-Driven POJOs

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#jms-asynchronousMessageReception)

In a fashion similar to a Message-Driven Bean (MDB) in the EJB world, the Message-Driven POJO (MDP) acts as a receiver for JMS messages. The one restriction (but see also below for the discussion of the MessageListenerAdapter class) on an MDP is that it must implement the javax.jms.MessageListener interface. Please also be aware that in the case where your POJO will be receiving messages on multiple threads, it is important to ensure that your implementation is thread-safe.

Below is a simple implementation of an MDP:

```java
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.MessageListener;
import javax.jms.TextMessage;

public class ExampleListener implements MessageListener {

    public void onMessage(Message message) {
        if (message instanceof TextMessage) {
            try {
                System.out.println(((TextMessage) message).getText());
            }
            catch (JMSException ex) {
                throw new RuntimeException(ex);
            }
        }
        else {
            throw new IllegalArgumentException("Message must be of type TextMessage");
        }
    }

}
```

Once you’ve implemented your MessageListener, it’s time to create a message listener container.

Find below an example of how to define and configure one of the message listener containers that ships with Spring (in this case the DefaultMessageListenerContainer).

```xml
<!-- this is the Message Driven POJO (MDP) -->
<bean id="messageListener" class="jmsexample.ExampleListener" />

<!-- and this is the message listener container -->
<bean id="jmsContainer" class="org.springframework.jms.listener.DefaultMessageListenerContainer">
    <property name="connectionFactory" ref="connectionFactory"/>
    <property name="destination" ref="destination"/>
    <property name="messageListener" ref="messageListener" />
</bean>
```

## SessionAwareMessageListener interface

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#jms-receiving-async-session-aware-message-listener)

The SessionAwareMessageListener interface is a Spring-specific interface that provides a similar contract to the JMS MessageListener interface, but also provides the message handling method with access to the JMS Session from which the Message was received.

```java
package org.springframework.jms.listener;

public interface SessionAwareMessageListener {

    void onMessage(Message message, Session session) throws JMSException;

}
```

## MessageListenerAdapter

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#jms-receiving-async-message-listener-adapter)

The MessageListenerAdapter class is the final component in Spring’s asynchronous messaging support: in a nutshell, it allows you to expose almost any class as a MDP (there are of course some constraints).

```java
public interface MessageDelegate {

    void handleMessage(String message);

    void handleMessage(Map message);

    void handleMessage(byte[] message);

    void handleMessage(Serializable message);

}
```

```java
public class DefaultMessageDelegate implements MessageDelegate {
    // implementation elided for clarity...
}
```

In particular, note how the above implementation of the MessageDelegate interface (the above DefaultMessageDelegate class) has no JMS dependencies at all. It truly is a POJO that we will make into an MDP via the following configuration.

```xml
<!-- this is the Message Driven POJO (MDP) -->
<bean id="messageListener" class="org.springframework.jms.listener.adapter.MessageListenerAdapter">
    <constructor-arg>
        <bean class="jmsexample.DefaultMessageDelegate"/>
    </constructor-arg>
</bean>

<!-- and this is the message listener container... -->
<bean id="jmsContainer" class="org.springframework.jms.listener.DefaultMessageListenerContainer">
    <property name="connectionFactory" ref="connectionFactory"/>
    <property name="destination" ref="destination"/>
    <property name="messageListener" ref="messageListener" />
</bean>
```

## Processing messages within transactions

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#jms-tx-participation)

## Support for JCA Message Endpoints

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#jms-jca-message-endpoint-manager)

## JMS namespace support

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#jms-namespace)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:jms="http://www.springframework.org/schema/jms"
        xsi:schemaLocation="
            http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
            http://www.springframework.org/schema/jms http://www.springframework.org/schema/jms/spring-jms.xsd">

    <!-- bean definitions here -->

</beans>
```