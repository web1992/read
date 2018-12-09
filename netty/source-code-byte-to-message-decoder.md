# ByteToMessageDecoder

Netty 中负责把字节流转化成一个具体对象的基类

> 来自 Netty docs:

Generally frame detection should be handled earlier in the pipeline by adding a `DelimiterBasedFrameDecoder`, `FixedLengthFrameDecoder`, `LengthFieldBasedFrameDecoder`, or `LineBasedFrameDecoder`.

If a custom frame decoder is required, then one needs to be careful when implementing one with `ByteToMessageDecoder`. Ensure there are enough bytes in the buffer for a complete frame by checking `ByteBuf.readableBytes()`. If there are not enough bytes for a complete frame, return without modifying the reader index to allow more bytes to arrive.

To check for complete frames without modifying the reader index, use methods like ByteBuf.getInt(int). One MUST use the reader index when using methods like `ByteBuf.getInt(int)`. For example `calling in.getInt(0)` is assuming the frame starts at the beginning of the buffer, which is not always the case. Use `in.getInt(in.readerIndex())` instead.

## 读事件流程

读事件是在`NioEventLoop`的`processSelectedKey`中进行触发的

```java
if ((readyOps & (SelectionKey.OP_READ | SelectionKey.OP_ACCEPT)) != 0 || readyOps == 0) {
    unsafe.read();
}
```

`OP_READ`,`OP_ACCEPT` 的实现原理可以参照这个文章[java nio SelectionKey](https://github.com/web1992/read/blob/master/java/nio-selection-key.md)

以`LengthFieldBasedFrameDecoder`为例，在初始的时候，`LengthFieldBasedFrameDecoder`被添加到 pipeline 中，当读事件触发时，通过 pipeline 转发到`LengthFieldBasedFrameDecoder`
而`LengthFieldBasedFrameDecoder`继承了`ByteToMessageDecoder`,读事件先被`ByteToMessageDecoder`处理
而后子类`LengthFieldBasedFrameDecoder`继续进行处理

方法调用流程：

```java
NioEventLoop -> pipeline -> ByteToMessageDecoder-> LengthFieldBasedFrameDecoder -> ...
```

```java
ByteToMessageDecoder
    -> channelRead
    -> callDecode
    -> decodeRemovalReentryProtection
    -> LengthFieldBasedFrameDecoder#decode
        -> decode
```

## channelRead

```java
 @Override
 public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
     if (msg instanceof ByteBuf) {
         // 如果是ByteBuf开始处理byte数据
         CodecOutputList out = CodecOutputList.newInstance();
         try {
             ByteBuf data = (ByteBuf) msg;
             // cumulation为空，是第一次进行读消息,直接把ByteBuf给cumulation
             first = cumulation == null;
             if (first) {
                 cumulation = data;
             } else {
                 // 否则就使用cumulator这个byte字节累加器，进行数据累加
                 // 例子：10byte的数据发送了两次，第一次2btye，第二次8byte,
                 // 那么这个channelRead就会触发两次
                 // 第一次cumulation中存储了2byte，第二次cumulation累加8byte，总共10byte
                 // 每次socket通信发送多少字节，是tcp协议决定的，tcp协议会对发送的数据进行缓存
                 // 缓存区满了，就进行数据的发送,可参照tpc协议的实现
                 cumulation = cumulator.cumulate(ctx.alloc(), cumulation, data);
             }
             // 去进行解码操作，其实对byte字节按照一定的规则进行解析
             callDecode(ctx, cumulation, out);
         } catch (DecoderException e) {
             throw e;
         } catch (Exception e) {
             throw new DecoderException(e);
         } finally {
             if (cumulation != null && !cumulation.isReadable()) {
                 numReads = 0;
                 cumulation.release();
                 cumulation = null;
             } else if (++ numReads >= discardAfterReads) {
                 // We did enough reads already try to discard some bytes so we not risk to see a OOME.
                 // See https://github.com/netty/netty/issues/4275
                 numReads = 0;
                 discardSomeReadBytes();
             }
             int size = out.size();
             decodeWasNull = !out.insertSinceRecycled();
             fireChannelRead(ctx, out, size);
             out.recycle();
         }
     } else {
         // 如果不是，数据已经进行了转化，让pipeline中的其他handler进行处理
         ctx.fireChannelRead(msg);
     }
 }
 /**
  * Cumulate {@link ByteBuf}s by merge them into one {@link ByteBuf}'s, using memory copies.
    累加器的实现
  */
 public static final Cumulator MERGE_CUMULATOR = new Cumulator() {
     @Override
     public ByteBuf cumulate(ByteBufAllocator alloc, ByteBuf cumulation, ByteBuf in) {
         try {
             final ByteBuf buffer;
             // expandCumulation这个扩容操作(本质是copy一份新的，替换旧的)有三种情况：
             // 1: cumulation.writerIndex() > cumulation.maxCapacity() - in.readableBytes()
             //    如果cumulation累加器空间不足
             //    空间不足肯定要扩容了，思想与ArrayList的实现一样
             // 2: cumulation.refCnt() > 1
             //    如果引用大于1，说要有其他地方在操作这个byteBuf,那么也copy一份
             //    防止并发修改的问题
             // 3: cumulation.isReadOnly()
             //    只读，为了执行writeBytes，也进行copy
             if (cumulation.writerIndex() > cumulation.maxCapacity() - in.readableBytes()
                 || cumulation.refCnt() > 1 || cumulation.isReadOnly()) {
                 // Expand cumulation (by replace it) when either there is not more room in the buffer
                 // or if the refCnt is greater then 1 which may happen when the user use slice().retain() or
                 // duplicate().retain() or if its read-only.
                 //
                 // See:
                 // - https://github.com/netty/netty/issues/2327
                 // - https://github.com/netty/netty/issues/1764
                 buffer = expandCumulation(alloc, cumulation, in.readableBytes());
             } else {
                 buffer = cumulation;
             }
             // 把in中的byte数据写入到cumulation累加器中
             buffer.writeBytes(in);
             return buffer;// 返回cumulation
         } finally {
             // We must release in in all cases as otherwise it may produce a leak if writeBytes(...) throw
             // for whatever release (for example because of OutOfMemoryError)
             // in中的数据已经copy到cumulation中了，释放in中的空间,防止内存溢出
             in.release();
         }
     }
 };
```

## callDecode

```java
  // 解码操作
  // 这个方法的作用：
  // 把ByteBuf中的数据进行解码
  // 从一个byte对象转化成其他对象,(或者变成一个新的bytebuf对象)，然后放入到out集合中
  // 如果out中存在解码成功的数据，那么把这个数据放入pipepline中进行下一步的操作
  protected void callDecode(ChannelHandlerContext ctx, ByteBuf in, List<Object> out) {
        try {
            while (in.isReadable()) {// 如果有可读的byte
                int outSize = out.size();

                if (outSize > 0) {// 如果outSize有解码完成的对象，进行下一个阶段的pipeline操作
                    fireChannelRead(ctx, out, outSize);
                    out.clear();// 清空

                    // Check if this handler was removed before continuing with decoding.
                    // If it was removed, it is not safe to continue to operate on the buffer.
                    //
                    // See:
                    // - https://github.com/netty/netty/issues/4635
                    if (ctx.isRemoved()) {
                        break;
                    }
                    outSize = 0;
                }

                int oldInputLength = in.readableBytes();// 获取可读的字节长度
                decodeRemovalReentryProtection(ctx, in, out);

                // Check if this handler was removed before continuing the loop.
                // If it was removed, it is not safe to continue to operate on the buffer.
                //
                // See https://github.com/netty/netty/issues/1664
                if (ctx.isRemoved()) {
                    break;
                }

                if (outSize == out.size()) {// 如果outSize没有变化（没有新生成解码之后的对象）
                    if (oldInputLength == in.readableBytes()) {// 并且可读的数据没有变化（byte中的数据没有达到可解码的长度,后续的解码器，就不会修改Bytebuf中的数据）
                        break;// 数据太少，结束本次解码
                    } else {
                        continue;
                    }
                }

                if (oldInputLength == in.readableBytes()) {
                    throw new DecoderException(
                            StringUtil.simpleClassName(getClass()) +
                                    ".decode() did not read anything but decoded a message.");
                }

                if (isSingleDecode()) {// 如果只解码一次，那么也结束
                    break;
                }
            }
        } catch (DecoderException e) {
            throw e;
        } catch (Exception cause) {
            throw new DecoderException(cause);
        }
    }
```

## LengthFieldBasedFrameDecoder

`LengthFieldBasedFrameDecoder`

> Netty docs:

A decoder that splits the received `ByteBuf` dynamically by the
value of the length field in the message. It is particularly useful when you
decode a binary message which has an integer header field that represents the
length of the message body or the whole message.

`LengthFieldBasedFrameDecoder` has many configuration parameters so
that it can decode any message with a length field, which is often seen in
proprietary client-server protocols.

一个通过长度来动态解析`ByteBuf` 的`解码器`,在解码一个二进制消息时,而这个消息有一个整数字段来代表消息体或者整个消息，十分有用。
`LengthFieldBasedFrameDecoder`提供了很多参数来配置消息满足不同的协议。通常在客户端-服务器这种协议下使用。

## 继承关系图

![LengthFieldBasedFrameDecoder](./images/LengthFieldBasedFrameDecoder.png)

`LengthFieldBasedFrameDecoder`继承了`ByteToMessageDecoder`

`ByteToMessageDecoder`继承了`ChannelInboundHandlerAdapter`,重写了`channelRead`,进行消息的读操作

`ByteToMessageDecoder`提供了`protected abstract void decode(ChannelHandlerContext ctx, ByteBuf in, List<Object> out)`
方法，提供了一个钩子，方便子类进行不同的实现

### LengthFieldBasedFrameDecoder 构造参数

理解了`LengthFieldBasedFrameDecoder`参数的作用，其实就明白了的实现

```java
    private final ByteOrder byteOrder;
    private final int maxFrameLength;// 这个消息的最大长度
    private final int lengthFieldOffset;// 代表消息长度字段的开始位置
    private final int lengthFieldLength;// 长度字段的长度
    private final int lengthFieldEndOffset;// 长度字段的结束位置 = 开始位置 + 长度字段的长度
    // 长度调整字段(这里存在两种情况,一是：长度字段表示整个消息体的字段(head+body),二是：长度字段只表示body的长度
    private final int lengthAdjustment;
    // 需要跳过的字段（丢弃的字段）
    private final int initialBytesToStrip;
    private final boolean failFast;
    private boolean discardingTooLongFrame;
    private long tooLongFrameLength;
    private long bytesToDiscard;
```

### demo

```java

lengthFieldOffset   = 0
lengthFieldLength   = 2
lengthAdjustment    = 0
initialBytesToStrip = 0 (= do not strip header)

BEFORE DECODE (14 bytes)         AFTER DECODE (14 bytes)
+--------+----------------+      +--------+----------------+
| Length | Actual Content |----->| Length | Actual Content |
| 0x000C | "HELLO, WORLD" |      | 0x000C | "HELLO, WORLD" |
+--------+----------------+      +--------+----------------+


lengthFieldOffset   = 0
lengthFieldLength   = 2
lengthAdjustment    = 0
initialBytesToStrip = 2 (= the length of the Length field)

BEFORE DECODE (14 bytes)         AFTER DECODE (12 bytes)
+--------+----------------+      +----------------+
| Length | Actual Content |----->| Actual Content |
| 0x000C | "HELLO, WORLD" |      | "HELLO, WORLD" |
+--------+----------------+      +----------------+

lengthFieldOffset   =  0
lengthFieldLength   =  2
lengthAdjustment    = -2 (= the length of the Length field)
initialBytesToStrip =  0

BEFORE DECODE (14 bytes)         AFTER DECODE (14 bytes)
+--------+----------------+      +--------+----------------+
| Length | Actual Content |----->| Length | Actual Content |
| 0x000E | "HELLO, WORLD" |      | 0x000E | "HELLO, WORLD" |
+--------+----------------+      +--------+----------------+

lengthFieldOffset   = 2 (= the length of Header 1)
lengthFieldLength   = 3
lengthAdjustment    = 0
initialBytesToStrip = 0

BEFORE DECODE (17 bytes)                      AFTER DECODE (17 bytes)
+----------+----------+----------------+      +----------+----------+----------------+
| Header 1 |  Length  | Actual Content |----->| Header 1 |  Length  | Actual Content |
|  0xCAFE  | 0x00000C | "HELLO, WORLD" |      |  0xCAFE  | 0x00000C | "HELLO, WORLD" |
+----------+----------+----------------+      +----------+----------+----------------+

lengthFieldOffset   = 0
lengthFieldLength   = 3
lengthAdjustment    = 2 (= the length of Header 1)
initialBytesToStrip = 0

BEFORE DECODE (17 bytes)                      AFTER DECODE (17 bytes)
+----------+----------+----------------+      +----------+----------+----------------+
|  Length  | Header 1 | Actual Content |----->|  Length  | Header 1 | Actual Content |
| 0x00000C |  0xCAFE  | "HELLO, WORLD" |      | 0x00000C |  0xCAFE  | "HELLO, WORLD" |
+----------+----------+----------------+      +----------+----------+----------------+

lengthFieldOffset   = 1 (= the length of HDR1)
lengthFieldLength   = 2
lengthAdjustment    = 1 (= the length of HDR2)
initialBytesToStrip = 3 (= the length of HDR1 + LEN)

BEFORE DECODE (16 bytes)                       AFTER DECODE (13 bytes)
+------+--------+------+----------------+      +------+----------------+
| HDR1 | Length | HDR2 | Actual Content |----->| HDR2 | Actual Content |
| 0xCA | 0x000C | 0xFE | "HELLO, WORLD" |      | 0xFE | "HELLO, WORLD" |
+------+--------+------+----------------+      +------+----------------+


lengthFieldOffset   =  1
lengthFieldLength   =  2
lengthAdjustment    = -3 (= the length of HDR1 + LEN, negative)
initialBytesToStrip =  3

BEFORE DECODE (16 bytes)                       AFTER DECODE (13 bytes)
+------+--------+------+----------------+      +------+----------------+
| HDR1 | Length | HDR2 | Actual Content |----->| HDR2 | Actual Content |
| 0xCA | 0x0010 | 0xFE | "HELLO, WORLD" |      | 0xFE | "HELLO, WORLD" |
+------+--------+------+----------------+      +------+----------------+
```

### LengthFieldBasedFrameDecoder#decode

```java
   // frame 长度的理解
   // 例子:
   // 如果一个java对象转化成byte字节进行网络传输，转化之后的字节长度是10 byte(用body来表示)
   // 不同的对象字节长度不同
   // 因此需要用额外的字节来表示这个java对象的长度是10 byte(用lenght表示)
   // 而Length本身也有长度,比如2byte 此时frame 就是12
   // 那么解码的时候需要byte转化成java对象的时候
   // 依然需要2 byte + 10 byte (lenght+body) 总计12字节的数据 此时frame 就是12
   /**
     * Create a frame out of the {@link ByteBuf} and return it.
     *
     * @param   ctx             the {@link ChannelHandlerContext} which this {@link ByteToMessageDecoder} belongs to
     * @param   in              the {@link ByteBuf} from which to read data
     * @return  frame           the {@link ByteBuf} which represent the frame or {@code null} if no frame could
     *                          be created.
     */
    protected Object decode(ChannelHandlerContext ctx, ByteBuf in) throws Exception {
        if (discardingTooLongFrame) {// 如果需要丢弃太长的byte,执行丢弃逻辑
            discardingTooLongFrame(in);
        }

        // 如果可读的数据小于长度字段的位置
        // 说明没有数据太少，无法读取，结束
        if (in.readableBytes() < lengthFieldEndOffset) {
            return null;
        }

        int actualLengthFieldOffset = in.readerIndex() + lengthFieldOffset;// 获取长度字段在byteBuf中的位置
        // 获取这个frame长度
        long frameLength = getUnadjustedFrameLength(in, actualLengthFieldOffset, lengthFieldLength, byteOrder);

        if (frameLength < 0) {// 如果小于0不合法,失败
            failOnNegativeLengthField(in, frameLength, lengthFieldEndOffset);
        }

        // 使用lengthAdjustment对frameLength进行调整
        // 加上这个lengthFieldEndOffset，frameLength表示head+body的长度
        frameLength += lengthAdjustment + lengthFieldEndOffset;

        // 再次判断,如果长度不够抛异常(如lengthAdjustment 设置的有问题)
        if (frameLength < lengthFieldEndOffset) {
            failOnFrameLengthLessThanLengthFieldEndOffset(in, frameLength, lengthFieldEndOffset);
        }
        // 如果超过限制
        if (frameLength > maxFrameLength) {
            exceededFrameLength(in, frameLength);
            return null;
        }

        // never overflows because it's less than maxFrameLength
        int frameLengthInt = (int) frameLength;
        if (in.readableBytes() < frameLengthInt) {// 如果可读的数据不够，返回null
            return null;
        }

        if (initialBytesToStrip > frameLengthInt) {// 如果丢弃的长度大于frame，解码失败
            failOnFrameLengthLessThanInitialBytesToStrip(in, frameLength, initialBytesToStrip);
        }
        in.skipBytes(initialBytesToStrip);// 解码的时候，跳过这些数据

        // extract frame
        int readerIndex = in.readerIndex();
        int actualFrameLength = frameLengthInt - initialBytesToStrip;// 计算实际的长度,那么需要丢弃的数据，不读
        // extractFrame中使用retainedSlice来截取ByteBuf,不会改变readerIndex
        // 因此使用 in.readerIndex 改变readindex
        ByteBuf frame = extractFrame(ctx, in, readerIndex, actualFrameLength);
        in.readerIndex(readerIndex + actualFrameLength);
        return frame;
    }
```

## ObjectDecoder 实现

`ObjectDecoder` 是 netty 实现的 java 序列化，可与`ObjectEncoder`一起使用

例子:[demo](https://github.com/web1992/java_note/tree/master/app_tools/src/main/java/cn/web1992/utils/demo/netty/serializable)

```java
 // 构造方法
public ObjectDecoder(ClassResolver classResolver) {
        // 1048576 btye = 1024 kb = 1M,支持的最大序列化对象是1M
        // classResolver 一个类加载器
        this(1048576, classResolver);
}


public ObjectDecoder(int maxObjectSize, ClassResolver classResolver) {
        // 调用了父类LengthFieldBasedFrameDecoder的构造方法
        // 第一个参数 maxObjectSize 最大farm
        // 第二个参数 0 = lengthFieldOffset 长读字段的起始位置
        // 第三个参数 4 = lengthFieldLength 长读字段的长度
        // 第四个参数 0 = lengthAdjustment 长读调整的值
        // 第五个参数 4 = initialBytesToStrip 需要跳过的字段
        super(maxObjectSize, 0, 4, 0, 4);
        this.classResolver = classResolver;
}

```

`LengthFieldBasedFrameDecoder`

```java
    public LengthFieldBasedFrameDecoder(
            int maxFrameLength,
            int lengthFieldOffset, int lengthFieldLength,
            int lengthAdjustment, int initialBytesToStrip) {
        this(
                maxFrameLength,
                lengthFieldOffset, lengthFieldLength, lengthAdjustment,
                initialBytesToStrip, true);
    }

```
