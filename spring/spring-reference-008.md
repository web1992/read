# Resources

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#resources)

## Introduction

Java’s standard java.net.URL class and standard handlers for various URL prefixes unfortunately are not quite adequate enough for all access to low-level resources. For example, there is no standardized URL implementation that may be used to access a resource that needs to be obtained from the classpath, or relative to a ServletContext. While it is possible to register new handlers for specialized URL prefixes (similar to existing handlers for prefixes such as http:), this is generally quite complicated, and the URL interface still lacks some desirable functionality, such as a method to check for the existence of the resource being pointed to.

## The Resource interface

```java
public interface Resource extends InputStreamSource {

    boolean exists();

    boolean isOpen();

    URL getURL() throws IOException;

    File getFile() throws IOException;

    Resource createRelative(String relativePath) throws IOException;

    String getFilename();

    String getDescription();

}
```

```java
public interface InputStreamSource {

    InputStream getInputStream() throws IOException;

}
```

## Built-in Resource implementations

- `UrlResource`
- `ClassPathResource`
- `FileSystemResource`
- `ServletContextResource`
- `InputStreamResource`
- `ByteArrayResource`

## ResourceLoader

The ResourceLoader interface is meant to be implemented by objects that can return (i.e. load) Resource instances.

```java
public interface ResourceLoader {

    Resource getResource(String location);

}
```

All application contexts implement the ResourceLoader interface, and therefore all application contexts may be used to obtain Resource instances.

When you call getResource() on a specific application context, and the location path specified doesn’t have a specific prefix, you will get back a Resource type that is appropriate to that particular application context. For example, assume the following snippet of code was executed against a ClassPathXmlApplicationContext instance:

```java
Resource template = ctx.getResource("some/resource/path/myTemplate.txt");
```

What would be returned would be a ClassPathResource; if the same method was executed against a FileSystemXmlApplicationContext instance, you’d get back a FileSystemResource. For a WebApplicationContext, you’d get back a ServletContextResource, and so on.

Resource strings

Prefix | Example | Explanation
------ | ------- | -----------
classpath: | classpath:com/myapp/config.xml | Loaded from the classpath.
file: | file:///data/config.xml | Loaded as a URL, from the filesystem. [1]
http: | http://myserver/logo.png | Loaded as a URL.
(none) | /data/config.xml Depends | on the underlying ApplicationContext.

## Resources as dependencies

 So if myBean has a template `property` of type `Resource`, it can be configured with a simple string for that resource, as follows:

```xml
<bean id="myBean" class="...">
    <!-- template property is Resource-->
    <property name="template" value="some/resource/path/myTemplate.txt"/>
</bean>
```

## Wildcards in application context constructor resource paths