# Chapter 4

## Connecting to ActiveMQ

This chapter covers

- A description and demonstration of ActiveMQ connector URIs
- How to connect your clients to ActiveMQ using transport connectors
- How to create a cluster of ActiveMQ message brokers using network connectors

## Understanding connector URIs

- Uniform resource identifiers (URIs)

`<scheme>:<scheme-specific-part>`

- URL (Uniform Resource Locator)

`tcp://localhost:61616`

This is a typical hierarchical URI used in ActiveMQ, which translates to “create a TCP
connection to the localhost on port 61616.”

## Transport connectors

The requirements of ActiveMQ users in terms of connectivity are diverse(多种多样).
Some users focus on performance, others on security, and so on. ActiveMQ tries to
cover all these aspects and provide a connector for every use case

### Configuring transport connectors

```xml
<transportConnectors>
    <transportConnector name="openwire" uri="tcp://localhost:61616" discoveryUri="multicast://default"/>
    <transportConnector name="ssl" uri="ssl://localhost:61617"/>
    <transportConnector name="stomp" uri="stomp://localhost:61613"/>
    <transportConnector name="xmpp" uri="xmpp://localhost:61222"/>
</transportConnectors>
```

The preceding snippet defines four transport connectors. Upon starting up
ActiveMQ using such a configuration file,

```java
ActiveMQConnectionFactory factory =
new ActiveMQConnectionFactory("tcp://localhost:61616");
Connection connection = factory.createConnection();
connection.start();
Session session =
connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
```

## Summary of network protocols used for client-broker communication

| Protocol | Description                                                                                                                                                                   |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TCP      | Default network protocol for most use cases.                                                                                                                                  |
| NIO      | Consider NIO protocol if you need to provide better scalability for connections from producers and consumers to the broker.                                                   |
| UDP      | Consider UDP protocol when you need to deal with the firewall between clients and the broker.                                                                                 |
| SSL      | Consider SSL when you want to secure communication between clients and the broker.                                                                                            |
| HTTP(S)  | Consider HTTP(S) when you need to deal with the firewall between clients and the broker.                                                                                      |
| VM       | Although not a network protocol per se, consider VM protocol when your broker and clients scommunicate with a broker that is embedded in the same Java Virtual Machine (JVM). |

## Transmission Control Protocol (TCP)

Before exchanging messages over the network, we need to serialize them to a suitable
form. Messages must be serialized in and out of a byte sequence to be sent over
the wire using what’s known as a _wire protocol_. The default wire protocol used in
ActiveMQ is called OpenWire. The protocol specification can be found on the
ActiveMQ website (http://mng.bz/u2eT). The OpenWire protocol isn’t specific to
the TCP network transport and can be used with other network protocols. Its main
purpose is to be efficient and allow fast exchange of messages over the network. Furthermore,
a standardized and open protocol such as OpenWire allows native
ActiveMQ clients to be developed for various programming environments.

```xml
<transportConnectors>
<transportConnector name="tcp"
uri="tcp://localhost:61616?trace=true"/>
</transportConnectors>
```

Some of the benefits of the TCP transport connector include the following:

- Efficiency—Since this connector uses the OpenWire protocol to convert messages
  to a stream of bytes (and back), it’s very efficient in terms of network
  usage and performance.
- Availability—TCP is one of the most widespread network protocols and has been
  supported in Java from the early days, so it’s almost certainly supported on your
  platform of choice.
- Reliability—The TCP protocol ensures that

## New I/O API protocol (NIO)

This makes the NIO transport connector more suitable
in situations where

- `You have a large number of clients you want to connect to the broker—Generally`, the
  number of clients that can connect to the broker is limited by the number of
  threads supported by the operating system. Since the NIO connector
  implementation starts fewer threads per client than the TCP connector, you
  should consider using NIO in case TCP doesn’t meet your needs.
- `You have a heavy network traffic to the broker—Again`, the NIO connector generally
  offers better performance than the TCP connector (in terms of using less
  resources on the broker side), so you can consider using it when you find that
  the TCP connector doesn’t meet your needs.

```xml
<transportConnectors>
<transportConnector
name="tcp"
uri="tcp://localhost:61616?trace=true" />
<transportConnector
name="nio"
uri="nio:localhost:61618?trace=true" />
</transportConnectors>
```

![active-nio](./images/active-nio.png)

## User Datagram Protocol (UDP)

User Datagram Protocol (UDP) along with TCP make up the core of internet protocols.
The purpose of these two protocols is identical—to send and receive data packets
(datagrams) over the network. But there are two main differences between them:

- `TCP is a stream-oriented protocol`, which means that the order of data packets is
  guaranteed. There’s no chance for data packets to be duplicated or arrive out
  of order. UDP, on the other hand, doesn’t guarantee packet ordering, so a
  receiver can expect data packets to be duplicated or arrive out of order.
- `TCP also guarantees reliability of packet delivery`, meaning that packets won’t be lost
  during the transport. This is ensured by maintaining an active connection
  between the sender and receiver. On the contrary, UDP is a connectionless protocol,
  so it can’t make such guarantees.

## Comparing the TCP and UDP transports

When considering the TCP and the UDP transports, questions arise that compare
these two protocols. When should you use the UDP transport instead of the TCP
transport? There are basically two such situations where the UDP transport offers an
advantage:

- The broker is located behind a firewall that you don’t control and you can
  access it only over UDP ports.
- You’re using time-sensitive messages and you want to eliminate network transport
  delay as much as possible.
  But there are also a couple of pitfalls regarding the UDP connector:
- Since UDP is unreliable, you can end up losing some of the messages, so your
  application should know how to deal with this situation.
- Network packets transmitted between clients and brokers aren’t just messages,
  but can also contain so-called control commands. If some of these
  control commands are lost due to UDP unreliability, the JMS connection
  could be endangered.

```xml
<transportConnectors>
<transportConnector
name="tcp"
uri="tcp://localhost:61616?trace=true"/>
<transportConnector
name="udp"
uri="udp://localhost:61618?trace=true" />
</transportConnectors>
```

## Secure Sockets Layer Protocol (SSL)

```xml
<transportConnectors>
<transportConnector name="ssl" uri="ssl://localhost:61617?trace=true" />
</transportConnectors>
```

This is accomplished using the following system properties:

- javax.net.ssl.keyStore—Defines which keystore the client should use
- javax.net.ssl.keyStorePassword—Defines an appropriate password for the keystore
- javax.net.ssl.trustStore—Defines an appropriate truststore the client should use
