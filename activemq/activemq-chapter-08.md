# Chapter 08

Integrating ActiveMQ with application servers

This chapter covers

- Integrating ActiveMQ with Apache Tomcat
- Integrating ActiveMQ with Jetty
- Integrating ActiveMQ with Apache Geronimo
- Integrating ActiveMQ with JBoss
- Understanding ActiveMQ and JNDI

The first type of application server implements the `Java Servlet specification` (http://mng.bz/cmMj) and is known
as a `web container`. `Apache Tomcat` and `Jetty` both fall into the category of web containers.

The second type of application server implements the `Java EE family of specifications` (http://mng.bz/NTSk) and is known as a `Java EE` container.
`Apache Geronimo` sand `JBoss` both fall into the category of Java EE containers.

其他容器没用过，只先了解 tomcat

## Integrating with Apache Tomcat

Apache Tomcat is arguably the most widely used Java web container available today.
Tomcat is used for both development and production throughout the world because
it’s `extremely robust`,`highly configurable`, and`commercially supported` by a number of companies.

> The Tomcat context.xml file

```xml
<Context reloadable="true">

<Resource auth="Container"
    name="jms/ConnectionFactory"
    type="org.apache.activemq.ActiveMQConnectionFactory"
    description="JMS Connection Factory"
    factory="org.apache.activemq.jndi.JNDIReferenceFactory"
    brokerURL="vm://localhost?brokerConfig=xbean:activemq.xml"
    brokerName="MyActiveMQBroker"/>

<Resource auth="Container"
    name="jms/FooQueue"
    type="org.apache.activemq.command.ActiveMQQueue"
    description="JMS queue"
    factory="org.apache.activemq.jndi.JNDIReferenceFactory"
    physicalName="FOO.QUEUE"/>

</Context>
```
