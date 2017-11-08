# Core Technologies

## 1 Lazy-initialized beans

spring  延时加载
[Lazy-initialized beans](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#beans-factory-lazy-init)

## 2 Singleton beans with prototype-bean dependencies

Singleton  bean 依赖 prototype bean [Link→](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#beans-factory-scopes-sing-prot-interaction)

当Singleton的bean依赖prototype bean 时，Singleton bean 中 prototype bean 其实还是只有一个的，因为Singleton 在初始时，已经确定了依赖，prototype bean 总是Singleton bean 初始化的那个bean

prototype scope(原型bean) 每次你从容器中 通过 `getBean()` 获取bean 的时候，拿到的都是新的bean(新的对象)

> When you use singleton-scoped beans with dependencies on prototype beans, be aware that dependencies are resolved at instantiation time. Thus if you dependency-inject a prototype-scoped bean into a singleton-scoped bean, a new prototype bean is instantiated and then dependency-injected into the singleton bean. The prototype instance is the sole instance that is ever supplied to the singleton-scoped bean.
> However, suppose you want the singleton-scoped bean to acquire a new instance of the prototype-scoped bean repeatedly at runtime. You cannot dependency-inject a prototype-scoped bean into your singleton bean, `because that injection occurs only once`, when the Spring container is instantiating the singleton bean and resolving and injecting its dependencies. If you need a new instance of a prototype bean at runtime more than once, see Section 7.4.6, “Method injection”