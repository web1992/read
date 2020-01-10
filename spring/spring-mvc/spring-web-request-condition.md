# RequestCondition

要理解 `RequestCondition` 在spring 中的作用，先看下下面的 `Demo`

## ConsumesRequestCondition demo

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

但是它们的 `consumes` 属性不同（ `consumes` 属性会映射的其实就是 `http` 请求中的 `Content-Type`）

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

## RequestMappingInfo

`RequestMappingInfo` 的初始化：

```java
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
   return builder.options(this.config).build();// build 方法如下
}

@Override
public RequestMappingInfo build() {
   ContentNegotiationManager manager = this.options.getContentNegotiationManager();
   PatternsRequestCondition patternsCondition = new PatternsRequestCondition(
         this.paths, this.options.getUrlPathHelper(), this.options.getPathMatcher(),
         this.options.useSuffixPatternMatch(), this.options.useTrailingSlashMatch(),
         this.options.getFileExtensions());
   return new RequestMappingInfo(this.mappingName, patternsCondition,
         new RequestMethodsRequestCondition(this.methods),
         new ParamsRequestCondition(this.params),
         new HeadersRequestCondition(this.headers),
         new ConsumesRequestCondition(this.consumes, this.headers),
         new ProducesRequestCondition(this.produces, this.headers, manager),
         this.customCondition);
}

// 上面说过 RequestMappingHandlerMapping 在初始化的时候
// 已经注册了所有的 url,而下面的 getMatchingCondition 就是通过 request 去匹配 RequestCondition
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
