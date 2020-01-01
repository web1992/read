# ContextLoaderListener

- `org.springframework.web.context.ContextLoaderListener`
- `WebApplicationContext`

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
