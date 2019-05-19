# serialization

这里简单分析下 `dubbo` 的序列化实现

序列化的目的就是把 `Java` 对象按照一定的格式变成 byte 数据，然后写入到网络进行网络的传输。

- [serialization](#serialization)
  - [summary](#summary)
  - [interface](#interface)
  - [Hessian2Serialization](#hessian2serialization)
  - [ObjectOutput](#objectoutput)
  - [ObjectInput](#objectinput)
  - [ChannelBufferOutputStream](#channelbufferoutputstream)
  - [ChannelBufferInputStream](#channelbufferinputstream)

## summary

- Serialization

> 实现了 `dubbo` 的自适应接口，可以进行不同的序列化协议实现的切换
>
> 同时定义了 `OutputStream` -> `ObjectOutput` 方法定义
>
> 和 `InputStream` -> `ObjectInput` 方法定义

- ObjectOutput

> 是对输出对象的抽象，比如可以是 `Hessian2ObjectOutput` `KryoObjectOutput`

- ObjectInput

> 是对输入对象的抽象，比如可以是 `Hessian2ObjectInput` `KryoObjectInput`

- ChannelBufferOutputStream

继承了 `OutputStream`,与 `ObjectOutput` 配合使用

- ChannelBufferInputStream

继承了 `InputStream`,与 `ObjectInput` 配合使用

关于 `ChannelBufferInputStream` 和 `ChannelBufferOutputStream` 可参照 [dubbo-input-output-stream.md](dubbo-input-output-stream.md)

## interface

```java
@SPI("hessian2")
public interface Serialization {

    /**
     * Get content type unique id, recommended that custom implementations use values greater than 20.
     *
     * @return content type id
     */
    byte getContentTypeId();

    /**
     * Get content type
     *
     * @return content type
     */
    String getContentType();

    /**
     * Get a serialization implementation instance
     *
     * @param url URL address for the remote service
     * @param output the underlying output stream
     * @return serializer
     * @throws IOException
     */
    @Adaptive
    ObjectOutput serialize(URL url, OutputStream output) throws IOException;

    /**
     * Get a deserialization implementation instance
     *
     * @param url URL address for the remote service
     * @param input the underlying input stream
     * @return deserializer
     * @throws IOException
     */
    @Adaptive
    ObjectInput deserialize(URL url, InputStream input) throws IOException;

}
```

## Hessian2Serialization

`Hessian2Serialization` 是 `dubbo` 默认的序列化实现，依赖 [hessian-lite](https://github.com/dubbo/hessian-lite/)

`hessian-lite` 也是阿里旗下的

这里看下 `Hessian2Serialization` 的代码实现十分简单，如下：

```java
public class Hessian2Serialization implements Serialization {

    public static final byte ID = 2;

    @Override
    public byte getContentTypeId() {
        return ID;// 用 id 来表示使用哪种序列化
    }

    @Override
    public String getContentType() {
        return "x-application/hessian2";// 这个目前的 dubbo 实现没有使用
    }

    @Override
    public ObjectOutput serialize(URL url, OutputStream out) throws IOException {
        // 生成 ObjectOutput 实现类
        // 底层是 hessian-lite 的 Hessian2Output对象
        return new Hessian2ObjectOutput(out);
    }

    @Override
    public ObjectInput deserialize(URL url, InputStream is) throws IOException {
        // 生成 ObjectInput 实现类
        // 底层是 hessian-lite 的 Hessian2Input 对象
        return new Hessian2ObjectInput(is);
    }

}
```

## ObjectOutput

`ObjectOutput` 是 dubbo 中`输出流`的抽象(可以理解为`java.io.OutputStream` 升级版本)

可以向流中写一个字符串(`writeUTF`)，写入一个 `boolean` (`writeBool`) 等等

他需要与 `OutputStream` 配合使用,`dubbo` 中实现了一个 `OutputStream` 的实现类 `ChannelBufferOutputStream`

当读取数据时会调用 `ObjectOutput` 的 `write*` 方法,类之间的调用链：

```java
ObjectOutput(Hessian2ObjectOutput).write -> OutputStream.write -> ChannelBuffer.write -> io.netty.buffer.ByteBuf
```

## ObjectInput

`ObjectInput` 是 dubbo 中`输入流`的抽象(可以理解为`java.io.InputStream` 升级版本)

可以从流中读取一个字符串(`readUTF`)，读取一个 `boolean` (`readBool`) 等等

他需要与 `InputStream` 配合使用,`dubbo` 中实现了一个 `InputStream` 的实现类 `ChannelBufferInputStream`

而当使用 `ObjectInput` 的 `read*` 方法写入数据的时候,类之间的调用链：

```java
ObjectInput(Hessian2ObjectInput).read -> InputStream.read -> ChannelBuffer.read -> io.netty.buffer.ByteBuf
```

## ChannelBufferOutputStream

```java
// ChannelBufferOutputStream 包装了 ChannelBuffer
// write 操作其实是向 ChannelBuffer 写入数据
public class ChannelBufferOutputStream extends OutputStream {

    private final ChannelBuffer buffer;
    private final int startIndex;

    public ChannelBufferOutputStream(ChannelBuffer buffer) {
        if (buffer == null) {
            throw new NullPointerException("buffer");
        }
        this.buffer = buffer;
        startIndex = buffer.writerIndex();
    }

    public int writtenBytes() {
        return buffer.writerIndex() - startIndex;
    }

    @Override
    public void write(byte[] b, int off, int len) throws IOException {
        if (len == 0) {
            return;
        }

        buffer.writeBytes(b, off, len);
    }

    @Override
    public void write(byte[] b) throws IOException {
        buffer.writeBytes(b);
    }

    @Override
    public void write(int b) throws IOException {
        buffer.writeByte((byte) b);
    }

    public ChannelBuffer buffer() {
        return buffer;
    }
}
```

## ChannelBufferInputStream

```java
// ChannelBufferInputStream 包装了 ChannelBuffer
// read 操作，其实都是从 ChannelBuffer 中读取数据
public class ChannelBufferInputStream extends InputStream {

    private final ChannelBuffer buffer;
    private final int startIndex;
    private final int endIndex;

    public ChannelBufferInputStream(ChannelBuffer buffer) {
        this(buffer, buffer.readableBytes());
    }

    public ChannelBufferInputStream(ChannelBuffer buffer, int length) {
        // ... 省略检查性代码
        this.buffer = buffer;
        startIndex = buffer.readerIndex();
        endIndex = startIndex + length;
        buffer.markReaderIndex();
    }

    public int readBytes() {
        return buffer.readerIndex() - startIndex;
    }

    @Override
    public int available() throws IOException {
        return endIndex - buffer.readerIndex();
    }

    @Override
    public void mark(int readlimit) {
        buffer.markReaderIndex();
    }

    @Override
    public boolean markSupported() {
        return true;
    }

    @Override
    public int read() throws IOException {
        if (!buffer.readable()) {
            return -1;
        }
        return buffer.readByte() & 0xff;
    }

    @Override
    public int read(byte[] b, int off, int len) throws IOException {
        int available = available();
        if (available == 0) {
            return -1;
        }

        len = Math.min(available, len);
        buffer.readBytes(b, off, len);
        return len;
    }

    @Override
    public void reset() throws IOException {
        buffer.resetReaderIndex();
    }

    @Override
    public long skip(long n) throws IOException {
        if (n > Integer.MAX_VALUE) {
            return skipBytes(Integer.MAX_VALUE);
        } else {
            return skipBytes((int) n);
        }
    }

    private int skipBytes(int n) throws IOException {
        int nBytes = Math.min(available(), n);
        buffer.skipBytes(nBytes);
        return nBytes;
    }

}
```
