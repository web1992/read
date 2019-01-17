# Chapter 14

Administering and monitoring ActiveMQ

This chapter covers

- Understanding JMX and ActiveMQ
- Using advisory messages to monitor ActiveMQ
- Administering ActiveMQ
- Logging configuration in ActiveMQ

## The JMX API and ActiveMQ

- Obtaining broker statistics, such as number of consumers (total or per destination)
- Adding new connectors or removing existing ones
- Changing some of the broker configuration properties

## Local vs. remote JMX access

```sh
if [ -z "$SUNJMX" ] ; then
#SUNJMX="-Dcom.sun.management.jmxremote.port=1099 \
-Dcom.sun.management.jmxremote.authenticate=false \
-Dcom.sun.management.jmxremote.ssl=false"
SUNJMX="-Dcom.sun.management.jmxremote"
fi
```

```xml
<broker xmlns="http://activemq.org/config/1.0" useJmx="true"
brokerName="localhost"
dataDirectory="${activemq.base}/data">
</broker>
```

## Exposing the JMX MBeans for ActiveMQ

```xml
<broker xmlns="http://activemq.org/config/1.0" useJmx="true"
brokerName="localhost"
dataDirectory="${activemq.base}/data">
<managementContext>
<managementContext connectorPort="2011" jmxDomainName="my-broker" />
</managementContext>
<transportConnectors>
<transportConnector name="openwire" uri="tcp://localhost:61616" />
</transportConnectors>
</broker>
```

## ENABLING REMOTE JMX ACCESS

```sh
if [ -z "$SUNJMX" ] ; then
SUNJMX="-Dcom.sun.management.jmxremote.port=1234 \
-Dcom.sun.management.jmxremote.authenticate=false \
-Dcom.sun.management.jmxremote.ssl=false"
fi
```

> NOTE

In order for the JMX remote access to work successfully, the /etc/hosts
file must be in order. Specifically, the /etc/hosts file must contain more than
just the entry for the localhost on 127.0.0.1. The /etc/hosts file must also contain
an entry for the real IP address and the hostname for a proper configuration.
Here’s an example of a proper configuration:

```
127.0.0.1 localhost
192.168.0.23 urchin.bsnyder.org urchin
```

Note the portion of the /etc/hosts file that contains an entry for the localhost
and an entry for the proper hostname and IP address.

## Restricting JMX access to a specific host

Configuring JMX password authentication

## Monitoring ActiveMQ with advisory messages

Advisory messages are delivered to topics whose names use the prefix ActiveMQ.
Advisory. For example, if you’re interested in knowing when connections to the broker
are started and stopped, you can see this activity by subscribing to the
`ActiveMQ.Advisory.Connection` topic. A variety of advisory topics are available
depending on what broker events interest you. Basic events such as starting and stopping
consumers, producers, and connections trigger advisory messages by default. But
for more complex events, such as sending messages to a destination without a consumer,
advisory messages must be explicitly enabled as shown next.

> Configuring advisory support

```xml
<broker xmlns="http://activemq.org/config/1.0" useJmx="true"
brokerName="localhost" dataDirectory="${activemq.base}/data"
advisorySupport="true">
<destinationPolicy>
<policyMap>
<policyEntries>
<policyEntry topic=">"
sendAdvisoryIfNoConsumers="true"/>
</policyEntries>
</policyMap>
</destinationPolicy>
<transportConnectors>
<transportConnector name="openwire" uri="tcp://localhost:61616" />
</transportConnectors>
</broker>
```

To demonstrate this functionality, we need to create a simple class that uses the advisory
messages. This Java class will use the advisory messages to print log messages to
standard output (stdout) whenever a consumer subscribes/unsubscribes, or a message
is sent to a topic that has no consumers subscribed to it.
