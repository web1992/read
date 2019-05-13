# InputStream & OutputStream

`dubbo` 中实现了两个自定义的 `InputStream` 和 `OutputStream` 的实现类

实现目的:

`dubbo` 中底层的通信框架是 `Netty`,当数据通过网络到达的时候，会被存在在 `io.netty.buffer.ByteBuf` 中

后续这个 `ByteBuf` 中的 `byte` 字节需要被反序列化，转化成 `java` 对象，而序列化框架的序列化操作都是基于 `InputStream` 和 `OutputStream` 的

因此需要自己实现`InputStream` 和 `OutputStream` 把 `io.netty.buffer.ByteBuf` 转化成 `InputStream` 和 `OutputStream` 然后交给序列化框架

转化成 `java` 对象

数据转化过程：

`io.netty.buffer.ByteBuf` -> `ChannelBuffer` -> `ChannelBufferInputStream` / `ChannelBufferOutputStream`

## ChannelBufferInputStream

```java
public class ChannelBufferInputStream extends InputStream {

    private final ChannelBuffer buffer;
    private final int startIndex;
    private final int endIndex;

}
```

## ChannelBufferOutputStream

```java

public class ChannelBufferOutputStream extends OutputStream {
    private final ChannelBuffer buffer;
    private final int startIndex;
}
```

## ChannelBuffer

`ChannelBuffer` 是 `dubbo` 对 `buffer` 的抽象，为之后切换通信框架提供了可能

```java
// org.apache.dubbo.remoting.transport.netty4.NettyBackedChannelBuffer
public class NettyBackedChannelBuffer implements ChannelBuffer {

    private ByteBuf buffer;// 来自 netty

    public NettyBackedChannelBuffer(ByteBuf buffer) {
        Assert.notNull(buffer, "buffer == null");
        this.buffer = buffer;
    }
}
```