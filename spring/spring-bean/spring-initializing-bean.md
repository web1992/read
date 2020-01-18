# InitializingBean

## afterPropertiesSet

```java
/*
 * Interface to be implemented by beans that need to react once all their properties
 * have been set by a {@link BeanFactory}: e.g. to perform custom initialization,
 * or merely to check that all mandatory properties have been set.
 */
public interface InitializingBean {

void afterPropertiesSet() throws Exception;
}
```

上面的代码中的 javadocs 的意思，看下面的例子

```java
// 以下面的这个 DemoController 为例子
// 如果 DemoController 实现了 InitializingBean 接口
// 那么在 执行 afterPropertiesSet 的时候
// userService 对象一定是有值得
// 也就是 all their properties have been set by a BeanFactory
@Controller
public class DemoController implements InitializingBean {

    @Autowired
    private UserService userService;

    @Override
    public void afterPropertiesSet() throws Exception {
        // userService 一定是已经被 Spring 进行了属性注入的
        // 一定不为空
        assert  null != userService;
    }
}
```

完成之后，调用 `afterPropertiesSet` 方法，可以实现自定义的 bean 初始化

比如 `RequestMappingHandlerMapping` 的 `afterPropertiesSet` 代码如下

```java
// RequestMappingHandlerMapping
public void afterPropertiesSet() {
// 初始化一些配置
this.config = new RequestMappingInfo.BuilderConfiguration();
this.config.setUrlPathHelper(getUrlPathHelper());
this.config.setPathMatcher(getPathMatcher());
this.config.setSuffixPatternMatch(this.useSuffixPatternMatch);
this.config.setTrailingSlashMatch(this.useTrailingSlashMatch);
this.config.setRegisteredSuffixPatternMatch(this.useRegisteredSuffixPatternMatch);
this.config.setContentNegotiationManager(getContentNegotiationManager());

// 调用父类 AbstractHandlerMethodMapping 
// 去遍历所有的 bean 对象，匹配那些 有Controller 和 RequestMapping 注解的bean
// 进行初始化的注册工作
super.afterPropertiesSet();
}

@Override
protected boolean isHandler(Class<?> beanType) {
    return (AnnotatedElementUtils.hasAnnotation(beanType, Controller.class) ||
    AnnotatedElementUtils.hasAnnotation(beanType, RequestMapping.class));
}
```
