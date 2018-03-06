# Integrating with other web frameworks

## Common configuration

config

On to specifics: all that one need do is to declare a ContextLoaderListener in the standard Java EE servlet web.xml file of one’s web application, and add a contextConfigLocation`<context-param/>` section (in the same file) that defines which set of Spring XML configuration files to load.

```xml
<listener>
    <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
</listener>

Find below the <context-param/> configuration:

<context-param>
    <param-name>contextConfigLocation</param-name>
    <param-value>/WEB-INF/applicationContext*.xml</param-value>
</context-param>
```

All Java web frameworks are built on top of the Servlet API, and so one can use the following code snippet to get access to this 'business context' ApplicationContext created by the ContextLoaderListener.

```java
WebApplicationContext ctx = WebApplicationContextUtils.getWebApplicationContext(servletContext);
```

