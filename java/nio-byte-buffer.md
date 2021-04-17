# ByteBuffer

A byte buffer. This class defines `six` categories of operations upon byte buffers:

- get()
- get(byte[])
- put(byte[])
- getChar()
- compact
- duplicate
- slice 创建一个 ByteBuffer 但是底层的 positon,limit,capacity 是独立的
- allocate
- wrap

```java
// ByteBuffer 集成了 Buffer
public abstract class ByteBuffer
    extends Buffer
    implements Comparable<ByteBuffer>
{
// ...
}
```

## Buffer

- `position` 读或者写，都会增加 `position` 的值
- `mark` 调用 `reset` 时,`position` 回到的位置

- `clear` 回到 `Buffer` 创建时候的状态,position=0,limit=capacity
- `flip` 设置 limit=position,position=0
- `rewind` (倒带) 设置 limit=limit,position=0

> `Buffer`方法列表：

| 方法                 |
| -------------------- |
| capacity             |
| position()           |
| position(int)        |
| limit                |
| limit(int)           |
| mark                 |
| reset                |
| clear                |
| flip                 |
| rewind               |
| remaining():int      |
| hasRemaining:boolean |
| isReadOnly           |
| hasArray             |
| array                |
| arrayOffset          |
| isDirect             |

## reference

- [https://www.jianshu.com/p/35cf0f348275](https://www.jianshu.com/p/35cf0f348275)
