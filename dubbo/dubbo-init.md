# dubbo init

一个简单的dubbo例子

- [demo of dubbo](https://github.com/web1992/dubbos)

## provider init

初始化过程，以下面的这个简单的xml配置为例子

> dubbo-provider.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xmlns="http://www.springframework.org/schema/beans"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-4.3.xsd
       http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!-- provider's application name, used for tracing dependency relationship -->
    <dubbo:application name="demo-provider"/>

    <dubbo:registry address="multicast://224.5.6.7:1234" />

    <!-- use dubbo protocol to export service on port 20880 -->
    <dubbo:protocol name="dubbo"/>

    <!-- service implementation, as same as regular local bean -->
    <bean id="demoService" class="cn.web1992.dubbo.demo.provider.DemoServiceImpl"/>

    <!-- declare the service interface to be exported -->
    <dubbo:service interface="cn.web1992.dubbo.demo.DemoService" ref="demoService"/>

</beans>
```

`dubbo`的初始化是以spring的扩展点为基础，进行配置，实现初始化的。

源码`org.apache.dubbo.config.spring.schema.DubboNamespaceHandler`

可以参照这个例子 [spring-reference-042](https://github.com/web1992/read/blob/master/spring/spring-reference-042.md)

下面是`DubboNamespaceHandler`源码：

```java
public class DubboNamespaceHandler extends NamespaceHandlerSupport {

    static {
        Version.checkDuplicate(DubboNamespaceHandler.class);
    }

    @Override
    public void init() {
        registerBeanDefinitionParser("application", new DubboBeanDefinitionParser(ApplicationConfig.class, true));
        registerBeanDefinitionParser("module", new DubboBeanDefinitionParser(ModuleConfig.class, true));
        registerBeanDefinitionParser("registry", new DubboBeanDefinitionParser(RegistryConfig.class, true));
        registerBeanDefinitionParser("config-center", new DubboBeanDefinitionParser(ConfigCenterBean.class, true));
        registerBeanDefinitionParser("metadata-report", new DubboBeanDefinitionParser(MetadataReportConfig.class, true));
        registerBeanDefinitionParser("monitor", new DubboBeanDefinitionParser(MonitorConfig.class, true));
        registerBeanDefinitionParser("provider", new DubboBeanDefinitionParser(ProviderConfig.class, true));
        registerBeanDefinitionParser("consumer", new DubboBeanDefinitionParser(ConsumerConfig.class, true));
        registerBeanDefinitionParser("protocol", new DubboBeanDefinitionParser(ProtocolConfig.class, true));
        registerBeanDefinitionParser("service", new DubboBeanDefinitionParser(ServiceBean.class, true));
        registerBeanDefinitionParser("reference", new DubboBeanDefinitionParser(ReferenceBean.class, false));
        registerBeanDefinitionParser("annotation", new AnnotationBeanDefinitionParser());
    }

}
```

从上面的代码可以看到熟悉的字样`application`，`service`，`reference`，`registry`等等

一个例子`<dubbo:service />` 这个可以看做是一个spring `<bean />`,bean标签需要Spring容器进行解析，
而`<dubbo:service />`是我们自定义的格式需要我们自己进行相关的`解析`，`初始化`等操作，而`DubboNamespaceHandler`
中包含了这些解析自定义标签相关的实现类。

`DubboBeanDefinitionParser`实现了`BeanDefinitionParser`中的`BeanDefinition parse(Element element, ParserContext parserContext)`方法

这个方法返回一个`BeanDefinition`,本质就是根据xml中的配置信息，生成一个`BeanDefinition`实例交给给spring容器。

## ServiceBean

`<dubbo:service />`标签的解析类是`ServiceBean`

> 类图：

![dubbo-ServiceBean](./images/dubbo-ServiceBean.png)

从类图中可以看到，`ServiceBean`实现了Spring相关类的很多接口，如`InitializingBean`,`ApplicationListener`

而dubbo相关初始是在`ApplicationListener`的实现方法中触发的，代码如下：

`export()`方法是入口

```java
    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        if (!isExported() && !isUnexported()) {
            if (logger.isInfoEnabled()) {
                logger.info("The service ready on spring started. service: " + getInterface());
            }
            export();
        }
    }
```

`ServiceBean`中会根据配置，来初始化服务，如使用`netty`启动本地服务，注册服务到`zookeeper`等

```java
ServiceBean
        -> Protocol
        -> ExchangeServer
        -> Transporter
        -> Server
```

```java
exportLocal(url);

```

## consumer init
