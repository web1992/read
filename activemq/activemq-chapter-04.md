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
