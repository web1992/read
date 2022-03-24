# Dubbo 泛型的实现

此文讲Dubbo泛型调用的实现细节。具体的使用例子参考文末连接。

- org.apache.dubbo.rpc.filter.GenericFilter
- org.apache.dubbo.rpc.service.GenericService

## GenericService

`GenericService` 类是暴露给开开发者的使用对象。主要的方法是`$invoke`和`$invokeAsync`。

```java
// GenericService 的定义
public interface GenericService {

    Object $invoke(String method, String[] parameterTypes, Object[] args) throws GenericException;

    default CompletableFuture<Object> $invokeAsync(String method, String[] parameterTypes, Object[] args) throws GenericException {
        Object object = $invoke(method, parameterTypes, args);
        if (object instanceof CompletableFuture) {
            return (CompletableFuture<Object>) object;
        }
        return CompletableFuture.completedFuture(object);
    }

}
```

使用例子：

```java
    ConfigurableApplicationContext context = SpringApplication.run(ConsumerApplicationGeneric.class, args);
    // dubbo 应用配置
    ApplicationConfig applicationConfig = context.getBean(ApplicationConfig.class);
    // dubbo 注册中心配置
    RegistryConfig registryConfig = context.getBean(RegistryConfig.class);
    // 引用远程服务
    // 该实例很重量，里面封装了所有与注册中心及服务提供方连接，请缓存
    ReferenceConfig<GenericService> reference = new ReferenceConfig<GenericService>();
    // 弱类型接口名
    reference.setInterface("cn.web1992.dubbo.demo.DemoService");
    //reference.setVersion("1.0.0");
    // 声明为泛化接口
    reference.setGeneric(true);
    reference.setApplication(applicationConfig);
    reference.setRegistry(registryConfig);
    // 用org.apache.dubbo.rpc.service.GenericService可以替代所有接口引用
    GenericService genericService = reference.get();
    // 基本类型以及Date,List,Map等不需要转换，直接调用
    Object result = genericService.$invoke("sayHello", new String[]{"java.lang.String"}, new Object[]{"world"});
    System.out.println(" user genericService >>> " + result);
```

上面是准备工作，下面思考几个问题：

- 执行RPC调用的时候，传输的对象是什么样子的，方法是什么，参数是如何传递的。
- 服务端在接受RPC之后的处理流程

RPC 请求最终会执行`DubboCodec#encodeRequestData` 方法进行数据编码(序列化)，被编码的对象是`RpcInvocation`。

```java
// DubboCodec#encodeRequestData
// 最终的请求会在这里进行序列化，进行网络的传输
@Override
protected void encodeRequestData(Channel channel, ObjectOutput out, Object data, String version) throws IOException {
    RpcInvocation inv = (RpcInvocation) data;
    out.writeUTF(version);
    out.writeUTF(inv.getAttachment(PATH_KEY));
    out.writeUTF(inv.getAttachment(VERSION_KEY));
    // 如果是泛型调用，方法名称是 $invoke或者$invokeAsync，需要在服务提供者的GenericFilter中进行处理
    out.writeUTF(inv.getMethodName());
    // 参数类型信息
    // 通过methodName+参数类型+接口类名 可以确定唯一的方法
    out.writeUTF(ReflectUtils.getDesc(inv.getParameterTypes()));
    Object[] args = inv.getArguments();
    if (args != null) {
        for (int i = 0; i < args.length; i++) {
            // 参数的值信息
            out.writeObject(encodeInvocationArgument(channel, inv, i));
        }
    }
    // 附加信息，Map对象（dubbo上下文透穿的实现）
    out.writeObject(inv.getAttachments());
}
```

## GenericFilter

`GenericFilter` 负责对泛型调用，转化成真正的方法调用。

```java

// CommonConstants
String $INVOKE = "$invoke";
String $INVOKE_ASYNC = "$invokeAsync";

@Activate(group = CommonConstants.PROVIDER, order = -20000)
public class GenericFilter extends ListenableFilter {

    public GenericFilter() {
        super.listener = new GenericListener();
    }

    @Override
    public Result invoke(Invoker<?> invoker, Invocation inv) throws RpcException {
        // 如果方法名称是 $invoke 或者$invokeAsync ，就执行下面的逻辑
        // 下面的逻辑是找到真正需要执行的方法
        if ((inv.getMethodName().equals($INVOKE) || inv.getMethodName().equals($INVOKE_ASYNC))
                && inv.getArguments() != null
                && inv.getArguments().length == 3
                && !GenericService.class.isAssignableFrom(invoker.getInterface())) {
            String name = ((String) inv.getArguments()[0]).trim();// 方法名称
            String[] types = (String[]) inv.getArguments()[1];// 方法的参数类型
            Object[] args = (Object[]) inv.getArguments()[2];//  方法的参数值信息
            try {
                // 找到
                Method method = ReflectUtils.findMethodByMethodSignature(invoker.getInterface(), name, types);

                // 省略参数解析代码
                // 根据不同的generic泛型的类型，解析参数 args

                // 解析参数之后，封装成 RpcInvocation 进行方法的调用
                RpcInvocation rpcInvocation =
                        new RpcInvocation(method, invoker.getInterface().getName(), invoker.getUrl().getProtocolServiceKey(), args,
                                inv.getObjectAttachments(), inv.getAttributes());
                rpcInvocation.setInvoker(inv.getInvoker());
                rpcInvocation.setTargetServiceUniqueName(inv.getTargetServiceUniqueName());

                return invoker.invoke(rpcInvocation);
            }
        }
    }
}
```

## Links

- [泛型调用示例](https://dubbo.apache.org/zh/docs/advanced/generic-reference/)