# CORS Support

- 1 [Introduction](#introduction)
- 2 [Controller method CORS configuration](#controller-method-cors-configuration)
- 3 [Global CORS configuration](#global-cors-configuration)
    - [JavaConfig](#javaconfig)
    - [XML namespace](#xml-namespace)
- 4 [Filter based CORS support](#filter-based-cors-support)

## Introduction

[link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#cors)

For security reasons, browsers prohibit AJAX calls to resources residing outside the current origin. For example, as you’re checking your bank account in one tab, you could have the evil.com website open in another tab. The scripts from evil.com should not be able to make AJAX requests to your bank API (e.g., withdrawing money from your account!) using your credentials.

Cross-origin resource sharing (CORS) is a W3C specification implemented by most browsers that allows you to specify in a flexible way what kind of cross domain requests are authorized, instead of using some less secured and less powerful hacks like IFRAME or JSONP.

As of Spring Framework 4.2, CORS is supported out of the box. CORS requests (including preflight ones with an OPTIONS method) are automatically dispatched to the various registered HandlerMappings. They handle CORS preflight requests and intercept CORS simple and actual requests thanks to a CorsProcessor implementation (DefaultCorsProcessor by default) in order to add the relevant CORS response headers (like Access-Control-Allow-Origin) based on the CORS configuration you have provided.

## Controller method CORS configuration

```java

@RestController
@RequestMapping("/account")
public class AccountController {

    @CrossOrigin
    @RequestMapping("/{id}")
    public Account retrieve(@PathVariable Long id) {
        // ...
    }

    @RequestMapping(method = RequestMethod.DELETE, path = "/{id}")
    public void remove(@PathVariable Long id) {
        // ...
    }
}

``
It is also possible to enable CORS for the whole controller:

```java

@CrossOrigin(origins = "http://domain2.com", maxAge = 3600)
@RestController
@RequestMapping("/account")
public class AccountController {

    @RequestMapping("/{id}")
    public Account retrieve(@PathVariable Long id) {
    // ...
    }

    @RequestMapping(method = RequestMethod.DELETE, path = "/{id}")
    public void remove(@PathVariable Long id) {
        // ...
    }
}

```

## Global CORS configuration


### JavaConfig

Enabling CORS for the whole application is as simple as:

```java

@Configuration
@EnableWebMvc
public class WebConfig extends WebMvcConfigurerAdapter {

@Override
public void addCorsMappings(CorsRegistry registry) {
    registry.addMapping("/**");
}
}

```

You can easily change any properties, as well as only apply this CORS configuration to a specific path pattern:

```java

@Configuration
@EnableWebMvc
public class WebConfig extends WebMvcConfigurerAdapter {

@Override
public void addCorsMappings(CorsRegistry registry) {
    registry.addMapping("/api/**")
    .allowedOrigins("http://domain2.com")
    .allowedMethods("PUT", "DELETE")
    .allowedHeaders("header1", "header2", "header3")
    .exposedHeaders("header1", "header2")
    .allowCredentials(false).maxAge(3600);
}
}

```

### XML namespace

The following minimal XML configuration enables CORS for the /** path pattern with the same default properties as with the aforementioned JavaConfig examples:

```xml

<mvc:cors>
    <mvc:mapping path="/**" />
</mvc:cors>

It is also possible to declare several CORS mappings with customized properties:

```xml
<mvc:cors>

<mvc:mapping path="/api/**"
    allowed-origins="http://domain1.com, http://domain2.com"
    allowed-methods="GET, PUT"
    allowed-headers="header1, header2, header3"
    exposed-headers="header1, header2" allow-credentials="false"
    max-age="123" />

<mvc:mapping path="/resources/**"
    allowed-origins="http://domain1.com" />

</mvc:cors>
```

## Filter based CORS support

In order to support CORS with filter-based security frameworks like Spring Security, or with other libraries that do not support natively CORS, Spring Framework also provides a CorsFilter. Instead of using @CrossOrigin or WebMvcConfigurer#addCorsMappings(CorsRegistry), you need to register a custom filter defined like bellow:

```java
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

public class MyCorsFilter extends CorsFilter {

public MyCorsFilter() {
    super(configurationSource());
}

private static UrlBasedCorsConfigurationSource configurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowCredentials(true);
    config.addAllowedOrigin("http://domain1.com");
    config.addAllowedHeader("*");
    config.addAllowedMethod("*");
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", config);
    return source;
}
}
```

>note

You need to ensure that CorsFilter is ordered before the other filters, see [this blog post](https://spring.io/blog/2015/06/08/cors-support-in-spring-framework#filter-based-cors-support) about how to configure Spring Boot accordingly.