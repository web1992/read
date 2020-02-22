# RequestMappingHandlerAdapter

`invokeHandlerMethod` 是 `RequestMappingHandlerAdapter` 中的核心方法

`RequestMappingHandlerAdapter` 负责`参数的解析`，`方法调用`，`返回值处理`

## RequestMappingHandlerAdapter init

`RequestMappingHandlerAdapter` 初始化方法调用链

```java
afterPropertiesSet -> initControllerAdviceCache // ControllerAdvice 注解
   -> getDefaultArgumentResolvers // 如解析 RequestParam 注解
   -> getDefaultInitBinderArgumentResolvers
   -> getDefaultReturnValueHandlers // 比如 ModelAndView

// 可以实现 HandlerMethodArgumentResolver 接口进行自定义的参数解析
// 类似这中可扩展的设计在 Spring 中有很多，可以在后续的结构设计中进行类型的扩展设计，提供灵活性
```

## afterPropertiesSet

```java
@Override
public void afterPropertiesSet() {
   // Do this first, it may add ResponseBody advice beans
   initControllerAdviceCache();

   if (this.argumentResolvers == null) {
       // 参数解析的类
      List<HandlerMethodArgumentResolver> resolvers = getDefaultArgumentResolvers();
      this.argumentResolvers = new HandlerMethodArgumentResolverComposite().addResolvers(resolvers);
   }
   if (this.initBinderArgumentResolvers == null) {
      List<HandlerMethodArgumentResolver> resolvers = getDefaultInitBinderArgumentResolvers();
      this.initBinderArgumentResolvers = new HandlerMethodArgumentResolverComposite().addResolvers(resolvers);
   }
   if (this.returnValueHandlers == null) {
       // 返回值解析相关的类
      List<HandlerMethodReturnValueHandler> handlers = getDefaultReturnValueHandlers();
      this.returnValueHandlers = new HandlerMethodReturnValueHandlerComposite().addHandlers(handlers);
   }
}
```

## invokeHandlerMethod

`invokeHandlerMethod` 方法主要目的就是`解析请求参数`和`处理返回结果`

解析参数的接口 `HandlerMethodArgumentResolver`

处理返回结果的结果 `HandlerMethodReturnValueHandler`

```java
// invokeHandlerMethod 下面的代码是在调用具体方法之前做做一些准备工作
// 然后执行 ServletInvocableHandlerMethod#invokeAndHandle 方法
protected ModelAndView invokeHandlerMethod(HttpServletRequest request,
      HttpServletResponse response, HandlerMethod handlerMethod) throws Exception {
   ServletWebRequest webRequest = new ServletWebRequest(request, response);
   try {
      WebDataBinderFactory binderFactory = getDataBinderFactory(handlerMethod);
      ModelFactory modelFactory = getModelFactory(handlerMethod, binderFactory);
      ServletInvocableHandlerMethod invocableMethod = createInvocableHandlerMethod(handlerMethod);
      if (this.argumentResolvers != null) {
         invocableMethod.setHandlerMethodArgumentResolvers(this.argumentResolvers);
      }
      if (this.returnValueHandlers != null) {
         invocableMethod.setHandlerMethodReturnValueHandlers(this.returnValueHandlers);
      }
      invocableMethod.setDataBinderFactory(binderFactory);
      invocableMethod.setParameterNameDiscoverer(this.parameterNameDiscoverer);
      ModelAndViewContainer mavContainer = new ModelAndViewContainer();
      mavContainer.addAllAttributes(RequestContextUtils.getInputFlashMap(request));
      modelFactory.initModel(webRequest, mavContainer, invocableMethod);
      mavContainer.setIgnoreDefaultModelOnRedirect(this.ignoreDefaultModelOnRedirect);
      AsyncWebRequest asyncWebRequest = WebAsyncUtils.createAsyncWebRequest(request, response);
      asyncWebRequest.setTimeout(this.asyncRequestTimeout);
      WebAsyncManager asyncManager = WebAsyncUtils.getAsyncManager(request);
      asyncManager.setTaskExecutor(this.taskExecutor);
      asyncManager.setAsyncWebRequest(asyncWebRequest);
      asyncManager.registerCallableInterceptors(this.callableInterceptors);
      asyncManager.registerDeferredResultInterceptors(this.deferredResultInterceptors);
      if (asyncManager.hasConcurrentResult()) {
         Object result = asyncManager.getConcurrentResult();
         mavContainer = (ModelAndViewContainer) asyncManager.getConcurrentResultContext()[0];
         asyncManager.clearConcurrentResult();
         if (logger.isDebugEnabled()) {
            logger.debug("Found concurrent result value [" + result + "]");
         }
         invocableMethod = invocableMethod.wrapConcurrentResult(result);
      }
      invocableMethod.invokeAndHandle(webRequest, mavContainer);
      if (asyncManager.isConcurrentHandlingStarted()) {
         return null;
      }
      return getModelAndView(mavContainer, modelFactory, webRequest);
   }
   finally {
      webRequest.requestCompleted();
   }
}
```

## ServletInvocableHandlerMethod.invokeForRequest

```java
public Object invokeForRequest(NativeWebRequest request, @Nullable ModelAndViewContainer mavContainer,
      Object... providedArgs) throws Exception {
   // 解析参数
   Object[] args = getMethodArgumentValues(request, mavContainer, providedArgs);
   if (logger.isTraceEnabled()) {
      logger.trace("Invoking '" + ClassUtils.getQualifiedMethodName(getMethod(), getBeanType()) +
            "' with arguments " + Arrays.toString(args));
   }
   // 调用方法
   Object returnValue = doInvoke(args);
   if (logger.isTraceEnabled()) {
      logger.trace("Method [" + ClassUtils.getQualifiedMethodName(getMethod(), getBeanType()) +
            "] returned [" + returnValue + "]");
   }
   return returnValue;
}
```

## HandlerMethodReturnValueHandler

## HandlerMethodArgumentResolver

## HttpMessageConverter
