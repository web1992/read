# SelectionKey

`java.nio.channels.SelectionKey`

java的nio中，`SelectionKey`用四个标识来表示可进行`某一事件`

下面通过源码理解它的实现原理

## 代码

先看下源码：

```java

    public abstract int readyOps();

    // 可进行读
    public static final int OP_READ = 1 << 0;
    // 可进行写
    public static final int OP_WRITE = 1 << 2;
    // 已经连接完成，可以进行读写
    public static final int OP_CONNECT = 1 << 3;
    // 可以接受新的连接
    public static final int OP_ACCEPT = 1 << 4;

    public final boolean isReadable() {
        return (readyOps() & OP_READ) != 0;
    }

    public final boolean isWritable() {
        return (readyOps() & OP_WRITE) != 0;
    }

    public final boolean isConnectable() {
        return (readyOps() & OP_CONNECT) != 0;
    }

    public final boolean isAcceptable() {
        return (readyOps() & OP_ACCEPT) != 0;
    }
```

从上面的代码中可以看到，代码中用`(readyOps() & OP_READ) != 0`来表示可以进行某个事件操作(这里是读事件)。

那么这个是怎么实现的呢？思考为什么`(readyOps() & OP_READ) != 0`就表示可以进行读事件了？

首先要知道 `&` 是java的二进制位运算，只有二进制每一位的值都是1时，结果才是1。（java还支持其它位操作，可自己Google）

即:

- 1 & 1 = 1
- 0 & 1 = 0
- 1 & 0 = 0
- 0 & 0 = 0

## 解读

下面的这个表格里面有每个标识的二进制和十进制

readyOps   | 十进制 | 二进制
-----------| ------| -----
OP_READ    |  1    | 00000001
OP_WRITE   |  4    | 00000100
OP_CONNECT |  8    | 00001000
OP_ACCEPT  |  16   | 00010000

从表格中可看到：

    - OP_READ    的1在第一位
    - OP_WRITE   的1在第三位
    - OP_CONNECT 的1在第四位
    - OP_ACCEPT  的1在第五位

`OP_READ & OP_WRITE` 二进制的&结果（二进制`00000000`,十进制是零）

计算过程：

- OP_READ & OP_WRITE
  - 00000001 # OP_READ
  - 00000100 # OP_WRITE
  - 00000000 # 结果

我们可以把这个四种值进行组合，他们`&`的结果都是零（二进制`00000000`）,因为它们二进制形式的1都是在不同的位置上

因此只有`readyOps()`是本身，结果才不是`零`。即 `OP_READ & OP_READ` = `00000001 & 00000001`结果是`不是零`(二进制`00000001`)

因此 `(readyOps() & OP_READ) != 0` 表示可以进行读事件

## 参考文章

- [Java位运算](http://xxgblog.com/2013/09/15/java-bitmask/)