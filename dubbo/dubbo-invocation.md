# Invocation

## interface

看下 `Invocation` 接口定义

```java
public interface Invocation {
    String getMethodName();
    Class<?>[] getParameterTypes();
    Object[] getArguments();
    Map<String, String> getAttachments();
    String getAttachment(String key);
    String getAttachment(String key, String defaultValue);
    Invoker<?> getInvoker();
}
```

`Invocation` 提供了获取方法调用时方法信息的功能,如：`方法名称`, `方法参数`, `参数类型`, `附件 attachment`, `Invoker`

比如在一次 `RPC` 调用的时候，我们在 `customer` 调用服务，肯定是要把调用的`方法名称`，`方法参数`，等信息通过 `TCP` 发送到

`provider` 端,而 `Invocation` 负责维护这些信息

`Invocation` 的实现类主要有两个 `RpcInvocation` 和 `DecodeableRpcInvocation`

`DecodeableRpcInvocation` 实现了 `org.apache.dubbo.remoting.Decodeable` 和 `Codec` 接口，提供了 `decode` 方法

## RpcInvocation uml

`org.apache.dubbo.rpc.RpcInvocation`

![Invocation](images/dubbo-DecodeableRpcInvocation.png)

## DecodeableRpcInvocation uml

`org.apache.dubbo.rpc.protocol.dubbo.DecodeableRpcInvocation`

![DecodeableRpcInvocation](./images/dubbo-DecodeableRpcInvocation.png)

`DecodeableRpcInvocation` 是在 `DubboCodec` 中生成的

关于 `DubboCodec` 可参考 [dubbo-codec2.md](dubbo-codec2.md)

这里我们不关心 TCP 解码相关的逻辑，我们只关心 `DecodeableRpcInvocation`

```java
// .... 省略其它代码
// DubboCodec decodeBody
// decode request. // 请求
Request req = new Request(id);
req.setVersion(Version.getProtocolVersion());
req.setTwoWay((flag & FLAG_TWOWAY) != 0);
if ((flag & FLAG_EVENT) != 0) {
    req.setEvent(true);
}
try {
    Object data;
    ObjectInput in = CodecSupport.deserialize(channel.getUrl(), is, proto);
    if (req.isHeartbeat()) {// 心跳
        data = decodeHeartbeatData(channel, in);
    } else if (req.isEvent()) {// 事件
        data = decodeEventData(channel, in);
    } else {// 数据请求
        DecodeableRpcInvocation inv;
        if (channel.getUrl().getParameter(
                Constants.DECODE_IN_IO_THREAD_KEY,
                Constants.DEFAULT_DECODE_IN_IO_THREAD)) {
            inv = new DecodeableRpcInvocation(channel, req, is, proto);
            inv.decode();// decode 解码
        } else {
            inv = new DecodeableRpcInvocation(channel, req,
                    new UnsafeByteArrayInputStream(readMessageData(is)), proto);
        }
        data = inv;
    }
    req.setData(data);// 把 DecodeableRpcInvocation 放到 Request的 data 中
} catch (Throwable t) {
    if (log.isWarnEnabled()) {
        log.warn("Decode request failed: " + t.getMessage(), t);
    }
    // bad request
    req.setBroken(true);
    req.setData(t);
}
return req;
```

### decode and encodeRequestData

```java
// 从上面的 Request 可知，我这里 decode 解码针对的是 请求
@Override
public Object decode(Channel channel, InputStream input) throws IOException {
    ObjectInput in = CodecSupport.getSerialization(channel.getUrl(), serializationType)
            .deserialize(channel.getUrl(), input);
    String dubboVersion = in.readUTF();// 1. 读取 dubbo 版本
    request.setVersion(dubboVersion);
    setAttachment(Constants.DUBBO_VERSION_KEY, dubboVersion);
    setAttachment(Constants.PATH_KEY, in.readUTF());// 2. 读取 path 接口的包名+类名称
    setAttachment(Constants.VERSION_KEY, in.readUTF());// 3. 读取方法的版本
    setMethodName(in.readUTF());// 4. 读取方法名称
    try {
        Object[] args;
        Class<?>[] pts;
        String desc = in.readUTF();// 5. 读取参数类型描述 比如：String.class => "Ljava/lang/String;"
        if (desc.length() == 0) {
            pts = DubboCodec.EMPTY_CLASS_ARRAY;
            args = DubboCodec.EMPTY_OBJECT_ARRAY;
        } else {
            pts = ReflectUtils.desc2classArray(desc);
            args = new Object[pts.length];
            for (int i = 0; i < args.length; i++) {
                try {
                    args[i] = in.readObject(pts[i]);// 6. 读取参数
                } catch (Exception e) {
                    if (log.isWarnEnabled()) {
                        log.warn("Decode argument failed: " + e.getMessage(), e);
                    }
                }
            }
        }
        setParameterTypes(pts);
        Map<String, String> map = (Map<String, String>) in.readObject(Map.class);// 7. 读取 map
        if (map != null && map.size() > 0) {
            Map<String, String> attachment = getAttachments();
            if (attachment == null) {
                attachment = new HashMap<String, String>();
            }
            attachment.putAll(map);
            setAttachments(attachment);
        }
        //decode argument ,may be callback
        for (int i = 0; i < args.length; i++) {
            args[i] = decodeInvocationArgument(channel, this, pts, i, args[i]);
        }
        setArguments(args);
    } catch (ClassNotFoundException e) {
        throw new IOException(StringUtils.toString("Read invocation data failed.", e));
    } finally {
        if (in instanceof Cleanable) {
            ((Cleanable) in).cleanup();//  清理
        }
    }
    return this;
}
```

> DubboCodec encodeRequestData

```java
// DubboCodec
// 对请求进行编码，然后经过序列化，进行网络传输
@Override
protected void encodeRequestData(Channel channel, ObjectOutput out, Object data, String version) throws IOException {
    RpcInvocation inv = (RpcInvocation) data;
    out.writeUTF(version);// 1. dubbo 版本
    out.writeUTF(inv.getAttachment(Constants.PATH_KEY));// 2. 路径，接口的包名+类名称
    out.writeUTF(inv.getAttachment(Constants.VERSION_KEY));// 3. 方法版本
    out.writeUTF(inv.getMethodName());// 4. 方法名称
    out.writeUTF(ReflectUtils.getDesc(inv.getParameterTypes()));// 5. 读取参数类型描述 比如：String.class => "Ljava/lang/String;"
    Object[] args = inv.getArguments();数
    if (args != null) {
        for (int i = 0; i < args.length; i++) {
            out.writeObject(encodeInvocationArgument(channel, inv, i));//6. 写入参数
        }
    }
    out.writeObject(RpcUtils.getNecessaryAttachments(inv));// 7. 写入 map
}

// 返回的是 map
public static Map<String, String> getNecessaryAttachments(Invocation inv) {
    Map<String, String> attachments = new HashMap<>(inv.getAttachments());
    attachments.remove(Constants.ASYNC_KEY);
    attachments.remove(Constants.FUTURE_GENERATED_KEY);
    return attachments;
}
```

从上面的 decode  和 encodeRequestData 方法中可以看到

`decode` 有 7 个步骤，`encodeRequestData` 也有 7 个步骤,他们分别一一对应