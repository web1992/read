# Chapter 06

Securing ActiveMQ

This chapter covers

- How to use authentication in ActiveMQ
- How to use authorization in ActiveMQ
- How to create a custom security plug-in for ActiveMQ
- Using certificate-based security with ActiveMQ

## Authentication

- Simple authentication plug-in—Handles credentials directly in the XML configuration file or in a properties file
- JAAS (Java Authentication and Authorization Service) authentication plug-in—Implements the JAAS API and provides a more powerful and customizable authentication solution

## Configuring the simple authentication plug-in

```xml
<broker ...>
<plugins>
<simpleAuthenticationPlugin>
<users>
<authenticationUser username="admin" password="password"
groups="admins,publishers,consumers"/>
<authenticationUser username="publisher" password="password"
groups="publishers,consumers"/>
<authenticationUser username="consumer" password="password"
groups="consumers"/>
<authenticationUser username="guest" password="password"
groups="guests"/>
</users>
</simpleAuthenticationPlugin>
</plugins>
</broker>
```

## Configuring the JAAS plug-in

using properties files, LDAP, and SSL certificates,

- [JAAS](http://mng.bz/BvvB)
- [`javax.security.auth.spi.LoginModule`](http://mng.bz/8zLV)

## Destination-level authorization

There are three types of user-level operations with JMS destinations:

- Read—The ability to receive messages from the destination
- Write—The ability to send messages to the destination
- Admin—The ability to administer the destination

```xml
<plugins>
<jaasAuthenticationPlugin
configuration="activemq-domain" />
<authorizationPlugin>
<map>
<authorizationMap>
<authorizationEntries>
<authorizationEntry topic=">"
read="admins" write="admins" admin="admins" />
<authorizationEntry topic="STOCKS.>"
read="consumers" write="publishers"
admin="publishers" />
<authorizationEntry topic="STOCKS.ORCL"
read="guests" />
<authorizationEntry topic="ActiveMQ.Advisory.>"
read="admins,publishers,consumers,guests"
write="admins,publishers,consumers,guests"
admin="admins,publishers,consumers,guests" />
</authorizationEntries>
</authorizationMap>
</map>
</authorizationPlugin>
</plugins>
```

A handy feature is the ability to define the destination value using wildcards. For
example, `STOCKS.>` means the entry applies to all destinations in the `STOCKS` path
recursively. You can find more information on wildcards in chapter 11. Also, the
authorization operations will accept either a single group or a comma-separated list of
groups as a value.

Considering this explanation, the configuration used in the previous example can
be translated as follows:

- Users from the admins group have full access to all topics
- Consumers can consume and publishers can publish to the destinations in the `STOCKS` path
- Guests can only consume from the `STOCKS.ORCL` topic

## Message-level authorization

`MessageAuthorizationPolicy`

```java
public class AuthorizationPolicy implements MessageAuthorizationPolicy {
    private static final Log LOG = LogFactory.getLog(AuthorizationPolicy.class);
    public boolean isAllowedToConsume(ConnectionContext context,Message message) {
            LOG.info(context.getConnection().getRemoteAddress());
            String remoteAddress = context.getConnection().getRemoteAddress();
        if (remoteAddress.startsWith("/127.0.0.1")) {
            LOG.info("Permission to consume granted");
            return true;
        } else {
            LOG.info("Permission to consume denied");
            return false;
        }
    }
}
```

Message-level authorization provides some powerful functionality with endless possibilities.
Although a simple example was used here, you can adapt it to any security
mechanism used in your project. Just bear in mind that a message authorization policy
is executed for `every message` that flows through the broker. So be careful not to
add functionality that could possibly `slow down` the flow of messages.

## Building a custom security plug-in
