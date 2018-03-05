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

## Controllers - The C in MVC

The default handler is still a very simple Controller interface, offering just two methods:

`void handleActionRequest(request,response)`
`ModelAndView handleRenderRequest(request,response)`

The framework also includes most of the same controller implementation hierarchy, such as AbstractController, SimpleFormController, and so on. Data binding, command object usage, model handling, and view resolution are all the same as in the servlet framework.

## Views - The V in MVC

All the view rendering capabilities of the servlet framework are used directly via a special bridge servlet named ViewRendererServlet. By using this servlet, the portlet request is converted into a servlet request and the view can be rendered using the entire normal servlet infrastructure. This means all the existing renderers, such as JSP, Velocity, etc., can still be used within the portlet.