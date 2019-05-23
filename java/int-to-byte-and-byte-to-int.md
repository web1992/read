# int to byte and byte to int

这里看下 `Java IO` 流处理 `(int -> byte)` 和 `(byte -> int)`的细节实现

## int to byte

[org.apache.dubbo.common.io.Bytes#int2bytes](https://github.com/apache/incubator-dubbo/blob/master/dubbo-common/src/main/java/org/apache/dubbo/common/io/Bytes.java#L126)

```java
// 这里用到了 无符号的右移 >>>
public static void int2bytes(int v, byte[] b, int off) {
    b[off + 3] = (byte) v;// b[off + 3] = (byte) v >>> 0;
    b[off + 2] = (byte) (v >>> 8);
    b[off + 1] = (byte) (v >>> 16);
    b[off + 0] = (byte) (v >>> 24);
    // b[off + 0] = (byte) ((v >> 24) & 0xFF);
}
```

下图的第一行代表要被转化成 `byte` 的 `int` ，一个 `int` 32 位，一个字节 8 位，因此一个 `int` 占用四个字节

`byte index` 标识 `int` 四个字节在 `byte` 中的位置

> `>>24` 二进制向右移动 24 ,`>>24`右移之后，对应的这一行`绿色`的最左边的8个字节，会被移动到`黄色`的位置，而后使用 `(byte)` 进行强制类型转化，只保留了最低位（`黄色`部分的8个字节），这样就就 `int` 的最高位的8个字节放到了 `byte` 数组 `index = 0` 的位置上

其它的 `>>>8` 和 `>>>16` 是同样的道理

`b[off + 3] = (byte) v` (int -> byte)强制转化，就是只保留最低位的 8 个字节，高位的会被舍弃

![int-to-byte.png](images/int-to-byte.png)

## byte to int

[org.apache.dubbo.common.io.Bytes#bytes2int](https://github.com/apache/incubator-dubbo/blob/master/dubbo-common/src/main/java/org/apache/dubbo/common/io/Bytes.java#L290)

```java
public static int bytes2int(byte[] b, int off) {
    return ((b[off + 3] & 0xFF) << 0) +
            ((b[off + 2] & 0xFF) << 8) +
            ((b[off + 1] & 0xFF) << 16) +
            ((b[off + 0]) << 24);
}
```