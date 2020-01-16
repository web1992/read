# HandlerException

`Spring` 异常处理

在 `DispatcherServlet.properties` 文件中声明了下面的三个异常处理类

- `ExceptionHandlerExceptionResolver`
- `ResponseStatusExceptionResolver`
- `DefaultHandlerExceptionResolver`

`Spring` 的异常入口在`DispatcherServlet` 中:

```java
DispatcherServlet.doDispatch
  -> DispatcherServlet.processDispatchResult
  -> DispatcherServlet.processHandlerException
```

## processHandlerException

```java
//  DispatcherServlet
// 下面的 handlerExceptionResolvers 就是上面的 DispatcherServlet.properties 的三个异常处理类
protected ModelAndView processHandlerException(HttpServletRequest request, HttpServletResponse response,
         @Nullable Object handler, Exception ex) throws Exception {

      // Check registered HandlerExceptionResolvers...
      ModelAndView exMv = null;
      if (this.handlerExceptionResolvers != null) {
          // ExceptionHandlerExceptionResolver
          // ResponseStatusExceptionResolver
          // DefaultHandlerExceptionResolver
          // for 就是按照上面3个类的顺序进行异常的处理，只要一个处理成功，就结束
         for (HandlerExceptionResolver handlerExceptionResolver : this.handlerExceptionResolvers) {
            exMv = handlerExceptionResolver.resolveException(request, response, handler, ex);
            if (exMv != null) {
               break;// 不为空就结束
            }
         }
      }
      if (exMv != null) {
         if (exMv.isEmpty()) {// 如果返回的 ModelAndView 为空这不进行 view 的渲染
            request.setAttribute(EXCEPTION_ATTRIBUTE, ex);
            return null;
         }
         // We might still need view name translation for a plain error model...
         if (!exMv.hasView()) {
            String defaultViewName = getDefaultViewName(request);
            if (defaultViewName != null) {
               exMv.setViewName(defaultViewName);
            }
         }
         if (logger.isDebugEnabled()) {
            logger.debug("Handler execution resulted in exception - forwarding to resolved error view: " + exMv, ex);
         }
         WebUtils.exposeErrorRequestAttributes(request, ex, getServletName());
         return exMv;
      }

      throw ex;
   }
```

## HandlerExceptionResolver

看下 `HandlerExceptionResolver` 异常处理接口类的定义

```java
// 如果返回的 ModelAndView.isEmpty 为空，这不需要进行 view 的渲染
// The returned {@code ModelAndView} may be {@linkplain ModelAndView#isEmpty() empty}
// to indicate that the exception has been resolved successfully but that no view
// should be rendered, for instance by setting a status code
ModelAndView resolveException(HttpServletRequest request,
                              HttpServletResponse response,
                              @Nullable Object handler,
                              Exception ex);
```

## ExceptionHandlerExceptionResolver

```java
// ExceptionHandlerExceptionResolver 的定义
public class ExceptionHandlerExceptionResolver
       extends AbstractHandlerMethodExceptionResolver
       implements ApplicationContextAware, InitializingBean{
}
```

从上面的方法看到 `ExceptionHandlerExceptionResolver` 实现了 `InitializingBean` 接口

(实现 `InitializingBean` 的目的就是实现 `afterPropertiesSet` 进行一些初始化工作)

下面看下 `afterPropertiesSet` 方法中做了什么

### afterPropertiesSet

```java
@Override
public void afterPropertiesSet() {
   // Do this first, it may add ResponseBodyAdvice beans
   initExceptionHandlerAdviceCache();
   if (this.argumentResolvers == null) {
      List<HandlerMethodArgumentResolver> resolvers = getDefaultArgumentResolvers();
      this.argumentResolvers = new HandlerMethodArgumentResolverComposite().addResolvers(resolvers);
   }
   if (this.returnValueHandlers == null) {
      List<HandlerMethodReturnValueHandler> handlers = getDefaultReturnValueHandlers();
      this.returnValueHandlers = new HandlerMethodReturnValueHandlerComposite().addHandlers(handlers);
   }
}
```

## initExceptionHandlerAdviceCache

`initExceptionHandlerAdviceCache` 中会调用 `ControllerAdviceBean.findAnnotatedBeans` 方法

```java
// ControllerAdviceBean
// 下面的方法就是从 Spring 容器中寻找所有有 @ControllerAdvice 注解的 bean
public static List<ControllerAdviceBean> findAnnotatedBeans(ApplicationContext applicationContext) {
   List<ControllerAdviceBean> beans = new ArrayList<>();
   for (String name : BeanFactoryUtils.beanNamesForTypeIncludingAncestors(applicationContext, Object.class)) {
      if (applicationContext.findAnnotationOnBean(name, ControllerAdvice.class) != null) {
         beans.add(new ControllerAdviceBean(name, applicationContext));
      }
   }
   return beans;
}
```

找到有 `@ControllerAdvice` 注解的bean 之后，对其进行包装生成 `ExceptionHandlerMethodResolver` 对象

```java
// ExceptionHandlerMethodResolver
public ExceptionHandlerMethodResolver(Class<?> handlerType) {
    // 找到 handlerType 下面的所有方法
   for (Method method : MethodIntrospector.selectMethods(handlerType, EXCEPTION_HANDLER_METHODS)) {
      for (Class<? extends Throwable> exceptionType : detectExceptionMappings(method)) {
         addExceptionMapping(exceptionType, method);// 放入到 ExceptionHandlerMethodResolver mappedMethods 中进行缓存
      }
   }
}

//  ExceptionHandlerMethodResolver
private List<Class<? extends Throwable>> detectExceptionMappings(Method method) {
   List<Class<? extends Throwable>> result = new ArrayList<>();
   detectAnnotationExceptionMappings(method, result);
   if (result.isEmpty()) {// 如果 @ExceptionHandler 为空，去方法参数上面找
      for (Class<?> paramType : method.getParameterTypes()) {
         if (Throwable.class.isAssignableFrom(paramType)) {
            result.add((Class<? extends Throwable>) paramType);
         }
      }
   }
   if (result.isEmpty()) {
      throw new IllegalStateException("No exception types mapped to " + method);
   }
   return result;
}
// ExceptionHandlerMethodResolver
// 寻找 @ExceptionHandler 注解的类
protected void detectAnnotationExceptionMappings(Method method, List<Class<? extends Throwable>> result) {
   ExceptionHandler ann = AnnotationUtils.findAnnotation(method, ExceptionHandler.class);
   Assert.state(ann != null, "No ExceptionHandler annotation");
   result.addAll(Arrays.asList(ann.value()));// 取 value 的值
}
```

从上面的初始化过程可以看出，需要实现自定义的异常处理类需要用到 `@ControllerAdvice` 和 注解 `@ExceptionHandler`

- `@ControllerAdvice` 作用在类上
- `@ExceptionHandler` 作用在类的方法上

## demo

```java
// 异常处理的demo
@RestControllerAdvice
public class ExceptionHandlerAdviceForRest {

    // 对自定义异常的处理
    @ExceptionHandler(RestException.class)
    public String customGenericExceptionHandler(RestException exception) {
        return "RestException " + exception.getMessage();
    }

    // 对 throwable 异常的的处理
    @ExceptionHandler(Throwable.class)
    public String throwable(Throwable exception) {
        return "Throwable " + exception.getMessage();
    }

    /**
     * 自定义异常 + ResponseStatus
     * @param exception
     * @return
     * 可以使用 ResponseStatus 进行 http code 的自定义
     */
    @ExceptionHandler(UnauthorizedException.class)
    //@ResponseStatus(value = HttpStatus.UNAUTHORIZED, reason = "UNAUTHORIZED")
    @ResponseStatus(value = HttpStatus.UNAUTHORIZED)
    public String unauthorized(UnauthorizedException exception) {
        // 下面的 return 可以使用 reason = "UNAUTHORIZED" 覆盖
        return "unauthorized " + exception.getMessage();
    }

}
```
