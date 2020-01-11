# RequestCondition

- [RequestCondition](#requestcondition)
  - [ConsumesRequestCondition demo](#consumesrequestcondition-demo)
  - [Define of RequestMappingInfo](#define-of-requestmappinginfo)
  - [RequestMappingInfo init](#requestmappinginfo-init)
  - [Define of RequestCondition](#define-of-requestcondition)
  - [RequestCondition.combine](#requestconditioncombine)

要理解 `RequestCondition` 在 `Spring` 中的作用，先看下下面的 `Demo`

## ConsumesRequestCondition demo

`ConsumesRequestCondition` 是 `RequestCondition` 的一个实现类之一

> **代码片段**

```java
@Controller("homeController")
public class HomeController {

    private static Logger LOG = LoggerFactory.getLogger(HomeController.class);

    @RequestMapping(value = {"/home"}, consumes = {"application/json"})
    @ResponseBody
    public String homeJson(HttpServletRequest request, HttpServletResponse response) throws Exception {

        return "home json";
    }

    @RequestMapping(value = {"/home"}, consumes = {"application/xml"})
    @ResponseBody
    public String homeXml(HttpServletRequest request, HttpServletResponse response) throws Exception {

        return "home xml";
    }
}
```

在 `HomeController` 中有二个方法，都有 `RequestMapping` 注解 ，并且 `value` 的值（也就是 `url` 路径都是一样的）

但是它们的 `consumes` 属性不同（ `consumes` 属性会映射的是 `http` 请求中的 `Content-Type`）

执行下面的 `curl` 命令就会得到不同的结果：

```sh
  # 命令
  curl -H "Content-Type: application/xml"  127.0.0.1:8080/home
  # 输出
  home xml
  # 命令
  curl -H "Content-Type: application/json"  127.0.0.1:8080/home
  # 输出
  home json
```

上面的例子中 `Content-Type` 分别是 `application/json` 和 `application/xml` 如果使用不同的 `Content-Type`  就会得到不同的输出结果

而上面的这种效果就是由 `ConsumesRequestCondition` 类实现的，而要了解 `ConsumesRequestCondition` 就要先了解 `RequestMappingInfo`

## Define of RequestMappingInfo

`RequestMappingInfo` 的定义

```java
// RequestMappingInfo 也实现了 RequestCondition
public final class RequestMappingInfo implements RequestCondition<RequestMappingInfo> {

}
```

## RequestMappingInfo init

`RequestMappingInfo` 的初始化：

```java
// RequestMappingInfo 是由 RequestMappingHandlerMapping 的 getMappingForMethod 方法创建的
// getMappingForMethod 方法有二个参数 method 和 handlerType
// method 的类型是 Method，handlerType 的类型是 Class
// 这样也是 @RequestMapping 注解支持在 Class 上面的原因（看代码里面的注释）
// RequestMappingHandlerMapping#getMappingForMethod
protected RequestMappingInfo getMappingForMethod(Method method, Class<?> handlerType) {
   // 获取 Method 上面的 @RequestMapping 信息并生成 RequestMappingInfo
   RequestMappingInfo info = createRequestMappingInfo(method);
   if (info != null) {
       // 获取 Class 上面的 @RequestMapping 信息并生成 RequestMappingInfo
      RequestMappingInfo typeInfo = createRequestMappingInfo(handlerType);
      if (typeInfo != null) {
         // Method 上面 RequestMappingInfo 的 与 Class 上的RequestMappingInfo 条件进行组合
         info = typeInfo.combine(info);
      }
   }
   return info;
}

// RequestMappingInfojava 构造
// RequestMappingHandlerMapping 在初始化的时候，会扫描所有的 Controller 中的方法
// 注册 url 与 RequestMappingInfo 关系
protected RequestMappingInfo createRequestMappingInfo(
      RequestMapping requestMapping, @Nullable RequestCondition<?> customCondition) {
   RequestMappingInfo.Builder builder = RequestMappingInfo
         .paths(resolveEmbeddedValuesInPatterns(requestMapping.path()))
         .methods(requestMapping.method()) // -> RequestMethodsRequestCondition
         .params(requestMapping.params()) // -> ParamsRequestCondition
         .headers(requestMapping.headers())// -> HeadersRequestCondition
         .consumes(requestMapping.consumes())// -> ConsumesRequestCondition
         .produces(requestMapping.produces())// -> ProducesRequestCondition
         .mappingName(requestMapping.name());
   if (customCondition != null) {
      builder.customCondition(customCondition);// -> customConditionHolder
   }
   return builder.options(this.config).build();// build 方法如下：
}

// build 方法中生成 多个 RequestCondition 对象
@Override
public RequestMappingInfo build() {
   ContentNegotiationManager manager = this.options.getContentNegotiationManager();
   PatternsRequestCondition patternsCondition = new PatternsRequestCondition(
         this.paths, this.options.getUrlPathHelper(), this.options.getPathMatcher(),
         this.options.useSuffixPatternMatch(), this.options.useTrailingSlashMatch(),
         this.options.getFileExtensions());
   return new RequestMappingInfo(this.mappingName, patternsCondition,
         new RequestMethodsRequestCondition(this.methods),// method
         new ParamsRequestCondition(this.params),// param
         new HeadersRequestCondition(this.headers),// headers
         new ConsumesRequestCondition(this.consumes, this.headers),
         new ProducesRequestCondition(this.produces, this.headers, manager),
         this.customCondition);
}

// 上面说过 RequestMappingHandlerMapping 在初始化的时候
// 已经注册了所有的 url,而下面的 getMatchingCondition 就是用 request 去匹配 RequestCondition
// 看最终是否有合格的 RequestCondition
// 这样就是 RequestCondition 的作用：
// 根据 request 匹配合适的 RequestCondition （匹配成功之后）创建 RequestMappingInfo 对象
// 而 RequestMappingInfo 对象中包含了 Contoller 对象
// 从而可以执行 Contoller 中的方法
@Override
@Nullable
public RequestMappingInfo getMatchingCondition(HttpServletRequest request) {
   // 匹配支持的方法，如GET，POST
   RequestMethodsRequestCondition methods = this.methodsCondition.getMatchingCondition(request);
   // @RequestMapping(value = {"/param"}, params = {"a=1"})
   // 进行参数匹配
   ParamsRequestCondition params = this.paramsCondition.getMatchingCondition(request);
   // 根据 Http 中的 headers 进行匹配，head 可以是你定义的 head
   HeadersRequestCondition headers = this.headersCondition.getMatchingCondition(request);
   // consumesCondition 根据 http 中 Content-Type 内容来匹配
   ConsumesRequestCondition consumes = this.consumesCondition.getMatchingCondition(request);
   ProducesRequestCondition produces = this.producesCondition.getMatchingCondition(request);
   // 如果上面的 RequestCondition 任何一个为空，那么匹配失败
   if (methods == null || params == null || headers == null || consumes == null || produces == null) {
      return null;
   }
   // 根据 url 进行匹配
   PatternsRequestCondition patterns = this.patternsCondition.getMatchingCondition(request);
   if (patterns == null) {
      return null;
   }
   // 自定义 RequestCondition 的匹配
   RequestConditionHolder custom = this.customConditionHolder.getMatchingCondition(request);
   if (custom == null) {
      return null;
   }
   return new RequestMappingInfo(this.name, patterns,
         methods, params, headers, consumes, produces, custom.getCondition());
}
```

## Define of RequestCondition

`RequestCondition` 的定义

```java
public interface RequestCondition<T> {

   // 把另一个 RequestCondition 进行组合
   T combine(T other);

   // 根据 requst 获取 T
   // 如果返回为空,说明请求没匹配到符合条件的方法（就是 Controller 中的方法）
   @Nullable
   T getMatchingCondition(HttpServletRequest request);

   // 对比
   int compareTo(T other, HttpServletRequest request);

}
```

`RequestCondition` 的实现类和 `RequestMapping` 属性对应的关系

| RequestCondition 实现类        | RequestMapping 的属性 |
| ------------------------------ | --------------------- |
| RequestMethodsRequestCondition | method                |
| ParamsRequestCondition         | params                |
| HeadersRequestCondition        | headers               |
| ConsumesRequestCondition       | consumes              |
| ProducesRequestCondition       | produces              |

`RequestCondition` 的这几个实现类就是对应的 `@RequestMapping` 中的属性，在创建`RequestMappingInfo` 的时候，把 `RequestMapping` 中的参数给 `XXXRequestCondition`进行解析

例子: 比如在解析 `method` 的时候，把 `method` 的值给 `RequestMethodsRequestCondition` 生成 `RequestMethodsRequestCondition`  对象

```java
// @RequestMapping 的定义
public @interface RequestMapping {

String name() default "";

@AliasFor("path")
String[] value() default {};

@AliasFor("value")
String[] path() default {};

RequestMethod[] method() default {};

String[] params() default {};

String[] headers() default {};

String[] consumes() default {};

String[] produces() default {};
```

## RequestCondition.combine

`RequestCondition`  这些方法最难理解就是 `combine` 方法了，下面看个例子：

```java
// RequestMapping 作用在 CombineController 类上面，并且指定了 method = POST
// 因此这个类下面的所有方法都只支持 POST 方法
// 举一个不是很恰当的场景，我想让 combine 方法也支持 GET 而不改动 CombineController 类上面的注解
// 怎么实现呢 ？
// 我可以在 combine 方法 RequestMapping 注解中添加一个 method = GET 就可以同时支持POST 和 GET 了
// 而这样做可行的而背后就是靠的 RequestMethodsRequestCondition#combine 方法
@Controller("combineController")
@RequestMapping(value = {"/combine"}, method = {RequestMethod.POST})
public class CombineController {
/**
 * GET 请求
 * curl  127.0.0.1:8080/combine/test
 * <p>
 * 输出：combine method is: GET
 * <p>
 * POST 请求
 * <p>
 * curl  -d "a=1"  127.0.0.1:8080/combine/test
 * <p>
 * 输出：combine method is: POST
 */
@RequestMapping(value = {"/test"}) // 只支持 POST 方法
// @RequestMapping(value = {"/test"}, method = {RequestMethod.GET}) // POST，GET 都支持
@ResponseBody
public String combine(HttpServletRequest request) throws Exception {
    return "combine method is: " + request.getMethod();
}
}
```

`RequestMethodsRequestCondition.combine`

```java
@Override
// 如果
// other.methods = [POST]
// this.methods = [GET]
// 那么
// 新的 RequestMethodsRequestCondition 的 methods=[POST,GET]
public RequestMethodsRequestCondition combine(RequestMethodsRequestCondition other) {
   Set<RequestMethod> set = new LinkedHashSet<>(this.methods);
   set.addAll(other.methods);
   // 生产一个新的 RequestMethodsRequestCondition（也就是由 combine 组合生产的新对象）
   // 也就同时支持了 POST 和 GET
   return new RequestMethodsRequestCondition(set);
}
```
