# Portlet MVC Framework

- 1 [Controllers - The C in MVC](#controllers---the-c-in-mvc)
- 2 [Views - The V in MVC](#views---the-v-in-mvc)
- 3 [The DispatcherPortlet](#the-dispatcherportlet)
- 4 [The ViewRendererServlet](#the-viewrendererservlet)

## Controllers - The C in MVC

The default handler is still a very simple Controller interface, offering just two methods:

`void handleActionRequest(request,response)`
`ModelAndView handleRenderRequest(request,response)`

The framework also includes most of the same controller implementation hierarchy, such as AbstractController, SimpleFormController, and so on. Data binding, command object usage, model handling, and view resolution are all the same as in the servlet framework.

## Views - The V in MVC

All the view rendering capabilities of the servlet framework are used directly via a special bridge servlet named `ViewRendererServlet`. By using this servlet, the portlet request is converted into a servlet request and the view can be rendered using the entire normal servlet infrastructure. This means all the existing renderers, such as JSP, Velocity, etc., can still be used within the portlet.

## The DispatcherPortlet

> Special beans in the WebApplicationContext

Expression & Explanation

handler mapping(s)

(Section 25.5, “Handler mappings”) a list of pre- and post-processors and controllers that will be executed if they match certain criteria (for instance a matching portlet mode specified with the controller)

controller(s)

(Section 25.4, “Controllers”) the beans providing the actual functionality (or at least, access to the functionality) as part of the MVC triad

view resolver

(Section 25.6, “Views and resolving them”) capable of resolving view names to view definitions

multipart resolver

(Section 25.7, “Multipart (file upload) support”) offers functionality to process file uploads from HTML forms

handler exception resolver

(Section 25.8, “Handling exceptions”) offers functionality to map exceptions to views or implement other more complex exception handling code

## The ViewRendererServlet

The rendering process in Portlet MVC is a bit more complex than in Web MVC. In order to reuse all the view technologies from Spring Web MVC, we must convert the PortletRequest / PortletResponse to HttpServletRequest / HttpServletResponse and then call the render method of the View. To do this, DispatcherPortlet uses a special servlet that exists for just this purpose: the ViewRendererServlet.

In order for DispatcherPortlet rendering to work, you must declare an instance of the ViewRendererServlet in the web.xml file for your web application as follows:

```xml
<servlet>
    <servlet-name>ViewRendererServlet</servlet-name>
    <servlet-class>org.springframework.web.servlet.ViewRendererServlet</servlet-class>
</servlet>

<servlet-mapping>
    <servlet-name>ViewRendererServlet</servlet-name>
    <url-pattern>/WEB-INF/servlet/view</url-pattern>
</servlet-mapping>
``

> Controllers

```java

public interface Controller {

    /**
     * Process the render request and return a ModelAndView object which the
     * DispatcherPortlet will render.
     */
    ModelAndView handleRenderRequest(RenderRequest request,
            RenderResponse response) throws Exception;

    /**
     * Process the action request. There is nothing to return.
     */
    void handleActionRequest(ActionRequest request,
            ActionResponse response) throws Exception;

}

```

etc ...
