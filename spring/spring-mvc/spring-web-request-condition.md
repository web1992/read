# RequestCondition

要理解 `RequestCondition` 在spring 中的作用，先看下下面的 `Demo`

## ConsumesRequestCondition demo

> **代码片段**

```java
@Controller("homeController")
public class HomeController {

    private static Logger LOG = LoggerFactory.getLogger(HomeController.class);

    /**
     * @param request  request
     * @param response response
     * @return
     * @throws Exception
     */
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

执行下面的 cul 命令就会得到不同的结果：

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

而上面的这种效果就是由 `ConsumesRequestCondition` 类实现的
