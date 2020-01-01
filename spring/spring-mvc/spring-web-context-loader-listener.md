# ContextLoaderListener

- [ContextLoaderListener](#contextloaderlistener)
  - [Class define](#class-define)
  - [ContextLoaderListener.initWebApplicationContext](#contextloaderlistenerinitwebapplicationcontext)
  - [ContextLoader.properties](#contextloaderproperties)
  - [ContextLoaderListener.configureAndRefreshWebApplicationContext](#contextloaderlistenerconfigureandrefreshwebapplicationcontext)

- `org.springframework.web.context.ContextLoaderListener`
- `org.springframework.web.context.support.XmlWebApplicationContext`

## Class define

```java
// ServletContextListener 是 servlet 规范里面的类，主要作用是在 web 容器（如 tomcat） 启动的时候收到通知(回调)
// 收到通知之后就可以开始 Spring 的初始化了
// ContextLoader 是 Spring 里面的类 负责具体的 Spring 初始化操作
// ContextLoaderListener 是一个启动类
// 目的是用来组合 ContextLoader 与 ServletContextListener 进行 Spring 的初始化
// tips:
// 当然可以直接使用 ContextLoader 实现 ServletContextListener 接口
// 但是这样 ContextLoader 就与 servlet 进行了耦合
// 而 ContextLoader 方法有很多，复杂的对象与 servlet 耦合显示不是好的设计
// 因此使用简单的类 ContextLoaderListener 与 servlet 耦合
// 在 ContextLoaderListener 中调用 ContextLoader 方法进行 Spring 的初始化
public class ContextLoaderListener extends ContextLoader implements ServletContextListener {

}
```

## ContextLoaderListener.initWebApplicationContext

```java
/**
 * Initialize the root web application context.
 */
// contextInitialized 就是 servlet 容器（如 tomcat）初始化开始的时候调用的类
@Override
public void contextInitialized(ServletContextEvent event) {
   // 在这里调用 initWebApplicationContext 进行 Spring appliaction context 的初始化
   initWebApplicationContext(event.getServletContext());
}

```

## ContextLoader.properties

```properties
# Default WebApplicationContext implementation class for ContextLoader.
# Used as fallback when no explicit context implementation has been specified as context-param.
# Not meant to be customized by application developers.

org.springframework.web.context.WebApplicationContext=org.springframework.web.context.support.XmlWebApplicationContext
```

`XmlWebApplicationContext` 是通过 `web.xml` 启动 `spring` 关键类

加载这个文件的地方在 `ContextLoader` 静态代码块中，如下：

```java
static {
   // Load default strategy implementations from properties file.
   // This is currently strictly internal and not meant to be customized
   // by application developers.
   try {
      ClassPathResource resource = new ClassPathResource(DEFAULT_STRATEGIES_PATH, ContextLoader.class);
      defaultStrategies = PropertiesLoaderUtils.loadProperties(resource);
   }
   catch (IOException ex) {
      throw new IllegalStateException("Could not load 'ContextLoader.properties': " + ex.getMessage());
   }
}
```

## ContextLoaderListener.configureAndRefreshWebApplicationContext

```java
// 这个方法的主要作用是调用 refresh 开始 Spring appliacton 的初始化了
protected void configureAndRefreshWebApplicationContext(ConfigurableWebApplicationContext wac, ServletContext sc) {
   if (ObjectUtils.identityToString(wac).equals(wac.getId())) {
      // The application context id is still set to its original default value
      // -> assign a more useful id based on available information
      String idParam = sc.getInitParameter(CONTEXT_ID_PARAM);
      if (idParam != null) {
         wac.setId(idParam);
      }
      else {
         // Generate default id...
         wac.setId(ConfigurableWebApplicationContext.APPLICATION_CONTEXT_ID_PREFIX +
               ObjectUtils.getDisplayString(sc.getContextPath()));
      }
   }
   wac.setServletContext(sc);
   String configLocationParam = sc.getInitParameter(CONFIG_LOCATION_PARAM);
   if (configLocationParam != null) {
      wac.setConfigLocation(configLocationParam);
   }
   // The wac environment's #initPropertySources will be called in any case when the context
   // is refreshed; do it eagerly here to ensure servlet property sources are in place for
   // use in any post-processing or initialization that occurs below prior to #refresh
   ConfigurableEnvironment env = wac.getEnvironment();
   if (env instanceof ConfigurableWebEnvironment) {
      ((ConfigurableWebEnvironment) env).initPropertySources(sc, null);
   }
   customizeContext(sc, wac);
   wac.refresh();
}
```

`refresh` 方法可以参考： [ApplicationContext](../spring-context/spring-application-context.md)

`spring` 的启动方法调用顺序v图可以参考 [spring-bean-load.png](../images/spring-bean-load.png)
