# RequestMapping

`@RequestMapping` 只是一个注解，这个注解会被解析变成 `XXXRequestCondition` 实例，

多个 `RequestCondition` 进行组合最终变成 `RequestMappingInfo` 对象

注册到 `RequestMappingHandlerMapping` 的 `mappingRegistry` 属性中(`mappingRegistry` 集成来自`AbstractHandlerMethodMapping`)

此外 `RequestMappingInfo` 也实现了 `RequestCondition`

可以参考 [RequestCondition](spring-web-request-condition.md) 的源码分析