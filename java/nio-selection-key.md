# SelectionKey

- [SelectionKey](#selectionkey)
  - [代码](#%e4%bb%a3%e7%a0%81)
  - [位运算](#%e4%bd%8d%e8%bf%90%e7%ae%97)
  - [解读](#%e8%a7%a3%e8%af%bb)
  - [更进一步](#%e6%9b%b4%e8%bf%9b%e4%b8%80%e6%ad%a5)
  - [参考文章](#%e5%8f%82%e8%80%83%e6%96%87%e7%ab%a0)

`java.nio.channels.SelectionKey`

java 的 nio 中，`SelectionKey`用四个标识来表示可进行`某一事件`(某个事件易已经发生)

下面通过源码理解它的实现技巧

## 代码

先看下源码：

```java
    // 插入一个事件
    public abstract SelectionKey interestOps(int ops);
    // 查询事件
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

## 位运算

首先要知道 `&` 是 java 的二进制位运算，只有二进制每一位的值都是 1 时，结果才是 1。（java 还支持其它位操作，可自己 Google）

即(二进制):

- 1 & 1 = 1
- 0 & 1 = 0
- 1 & 0 = 0
- 0 & 0 = 0

## 解读

下面的这个表格里面有每个标识的二进制和十进制

| readyOps   | 十进制 | 二进制   |
| ---------- | ------ | -------- |
| OP_READ    | 1      | 00000001 |
| OP_WRITE   | 4      | 00000100 |
| OP_CONNECT | 8      | 00001000 |
| OP_ACCEPT  | 16     | 00010000 |

从表格中可看到：

```txt
OP_READ    的1在第一位
OP_WRITE   的1在第三位
OP_CONNECT 的1在第四位
OP_ACCEPT  的1在第五位
```

`OP_READ & OP_WRITE` 二进制的&结果（二进制`00000000`,十进制是零）

计算过程：

- OP_READ & OP_WRITE
  - 00000001 # OP_READ
  - 00000100 # OP_WRITE
  - 00000000 # 结果

我们可以把这个四种值进行组合，他们`&`的结果都是零（二进制`00000000`）,因为它们二进制形式的 1 都是在不同的位置上

因此只有`readyOps()`是本身，结果才不是`零`。即 `OP_READ & OP_READ` = `00000001 & 00000001`结果是`不是零`(二进制`00000001`)

因此 `(readyOps() & OP_READ) != 0` 表示可以进行读事件

## 更进一步

如果 `readyOps()` 的二进制是`00000101`的时候，代表的什么事件？

- `00000101` & OP_READ = `00000101` & `00000001` = `00000001`
- `00000101` & OP_WRITE = `00000101` & `00000100` = `00000100`

上面的运算结果都不是零，代表了读事件(`OP_READ`)&写(`OP_WRITE`)事件!

那么`00000101`是怎么来的，可通过 `OP_READ | OP_WRITE` = `00000001` | `00000100` = `00000101`

我们可以通过`interestOps(int ops)`这个方法同时插入读事件&写事件

即: `interestOps(OP_READ | OP_WRITE)`

## 参考文章

- [Java 位运算](http://xxgblog.com/2013/09/15/java-bitmask/)
- [位运算](https://www.cnblogs.com/blog-cq/p/5793529.html)
