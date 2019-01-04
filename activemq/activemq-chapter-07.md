# Chapter 07

Creating Java applications with ActiveMQ

This chapter covers

- Embedding ActiveMQ in Java applications
- Embedding ActiveMQ using Spring
- Creating request/reply applications
- Writing JMS clients using Spring

## Embedding ActiveMQ using the BrokerService

`org.apache.activemq.broker.BrokerService`

> config

```xml
<?xml version="1.0" encoding="utf-8"?>

<broker xmlns="http://activemq.apache.org/schema/core" brokerName="myBroker" dataDirectory="${activemq.base}/data">  
  <transportConnectors>
    <transportConnector name="openwire" uri="tcp://localhost:61616"/>
  </transportConnectors>  
  <plugins>
    <simpleAuthenticationPlugin>
      <users>
        <authenticationUser username="admin" password="password" groups="admins,publishers,consumers"/>  
        <authenticationUser username="publisher" password="password" groups="publishers,consumers"/>  
        <authenticationUser username="consumer" password="password" groups="consumers"/>  
        <authenticationUser username="guest" password="password" groups="guests"/>
      </users>
    </simpleAuthenticationPlugin>
  </plugins>
</broker>

```

```java
public static void main(String[] args) throws Exception {
    BrokerService broker = new BrokerService();
    broker.setBrokerName("myBroker");
    broker.setDataDirectory("data/");
    SimpleAuthenticationPlugin authentication =
    new SimpleAuthenticationPlugin();
    List<AuthenticationUser> users =
    new ArrayList<AuthenticationUser>();
    users.add(new AuthenticationUser("admin","password","admins,publshers,consumers"));
    users.add(new AuthenticationUser("publisher","password","publishers,consumers"));
    users.add(new AuthenticationUser("consumer","password","consumers"));
    users.add(new AuthenticationUser("guest", "password","guests"));
    authentication.setUsers(users);
    broker.setPlugins(new BrokerPlugin[]{authentication});
    broker.addConnector("tcp://localhost:61616");
    broker.start();
    System.out.println();
    System.out.println("Press any key to stop the broker");
    System.out.println();
    System.in.read();
}
```

## Embedding ActiveMQ using the BrokerFactory

In many applications, you’ll want to be able to
initialize the broker using the same configuration files used to configure standalone
instances of the ActiveMQ broker. For that purpose ActiveMQ provides the utility
`org.apache.activemq.broker.BrokerFactory` class

```java
public class Factory {
    public static void main(String[] args) throws Exception {
        System.setProperty("activemq.base", System.getProperty("user.dir"));
        String configUri ="xbean:target/classes/org/apache/activemq/book/ch6/activemq-simple.xml";
        URI brokerUri = new URI(configUri);
        BrokerService broker = BrokerFactory.createBroker(brokerUri);
        broker.start();
        System.out.println();
        System.out.println("Press any key to stop the broker");
        System.out.println();
        System.in.read();
    }
}
```

```config
broker:(tcp://localhost:61616,network:static:tcp://remotehost:61616)?persistent=false&useJmx=true
```

## Embedding ActiveMQ using Spring

> config

```xml
<beans>
  <bean id="admins" class="org.apache.activemq.security.AuthenticationUser">
    <constructor-arg index="0" value="admin" />
    <constructor-arg index="1" value="password" />
    <constructor-arg index="2" value="admins,publisher,consumers" />
  </bean>
  <bean id="publishers"
  class="org.apache.activemq.security.AuthenticationUser">
    <constructor-arg index="0" value="publisher" />
    <constructor-arg index="1" value="password" />
    <constructor-arg index="2" value="publisher,consumers" />
  </bean>
  <bean id="consumers"
  class="org.apache.activemq.security.AuthenticationUser">
    <constructor-arg index="0" value="consumer" />
    <constructor-arg index="1" value="password" />
    <constructor-arg index="2" value="consumers" />
  </bean>
  <bean id="guests" class="org.apache.activemq.security.AuthenticationUser">
    <constructor-arg index="0" value="guest" />
    <constructor-arg index="1" value="password" />
    <constructor-arg index="2" value="guests" />
  </bean>
<bean id="simpleAuthPlugin"
class="org.apache.activemq.security.SimpleAuthenticationPlugin">
  <property name="users">
    <util:list>
      <ref bean="admins" />
      <ref bean="publishers" />
      <ref bean="consumers" />
      <ref bean="guests" />
    </util:list>
  </property>
</bean>
<bean id="broker" class="org.apache.activemq.broker.BrokerService" init-method="start" destroy-method="stop">
  <property name="brokerName" value="myBroker" />
  <property name="persistent" value="false" />
  <property name="transportConnectorURIs">
    <list>
      <value>tcp://localhost:61616</value>
      </list>
  </property>
  <property name="plugins">
      <list>
      <ref bean="simpleAuthPlugin"/>
    </list>
  </property>
</bean>
</beans>
```

## Using the BrokerFactoryBean

`org.apache.activemq.xbean.BrokerFactoryBean`

```xml
<beans>
<bean id="broker"
class="org.apache.activemq.xbean.BrokerFactoryBean">
<property name="config"
value="org/apache/activemq/book/ch6/activemq-simple.xml"/>
<property name="start" value="true" />
</bean>
</beans>
```