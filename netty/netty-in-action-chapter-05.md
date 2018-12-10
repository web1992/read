# CHAPTER 5

This chapter covers

- ByteBuf—Netty’s data container
- API details
- Use cases
- Memory allocation

## api

- `ByteBuf` abstract class
- `ByteBufHolder` interface

## ByteBuf

`ByteBuf` Netty’s data container

Netty’s API for data handling is exposed through two components—abstract class
ByteBuf and interface ByteBufHolder.
These are some of the advantages of the ByteBuf API:

- It’s extensible to user-defined buffer types.
- Transparent zero-copy is achieved by a built-in composite buffer type.
- Capacity is expanded on demand (as with the JDK StringBuilder).
- Switching between reader and writer modes doesn’t require calling ByteBuffer’s flip() method.
- Reading and writing employ distinct indices.
- Method chaining is supported.
- Reference counting is supported.
- Pooling is supported.

## Read/write operations

`getBytes(int, ...)`

Transfers this buffer’s data to a specified destination starting at
the given index

`readBytes(ByteBuf | byte[] destination, int dstIndex [,int length])`

Transfers data from the current ByteBuf starting at the current
readerIndex (for, if specified, length bytes) to a
destination ByteBuf or byte[], starting at the destination’s
dstIndex. The local readerIndex is incremented
by the number of bytes transferred.

`writeBytes(source ByteBuf | byte[] [,int srcIndex ,int length])`

Transfers data starting at the current writerIndex
from the specified source (ByteBuf or byte[]).
If srcIndex and length are provided, reading
starts at srcIndex and proceeds for length bytes.
The current writerIndex

## Other useful operations

| Name            | Description                                                                                                                   |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| isReadable()    | Returns true if at least one byte can be read.                                                                                |
| isWritable()    | Returns true if at least one byte can be written.                                                                             |
| readableBytes() | Returns the number of bytes that can be read.                                                                                 |
| writableBytes() | Returns the number of bytes that can be written.                                                                              |
| capacity()      | Returns the number of bytes that the ByteBuf can hold. After this it will try to expand again until maxCapacity() is reached. |
| maxCapacity()   | Returns the maximum number of bytes the ByteBuf can hold.                                                                     |
| hasArray()      | Returns true if the ByteBuf is backed by a byte array.                                                                        |
| array()         | Returns the byte array if the ByteBuf is backed by a byte array; otherwise it throws an UnsupportedOperationException.        |

## ByteBufHolder

ByteBufHolder is a good choice if you want to implement a message object that stores its payload in a ByteBuf.

## ByteBufAllocator

- `PooledByteBufAllocator`
- `UnpooledByteBufAllocator`

Netty provides two implementations of ByteBufAllocator: `PooledByteBufAllocator`
and `UnpooledByteBufAllocator`. The former pools ByteBuf instances to improve performance and minimize memory fragmentation. This implementation uses an efficient approach to memory allocation known as jemalloc4 that has been adopted by a
number of modern OSes. The latter implementation doesn’t pool `ByteBuf` instances
and returns a new instance every time it’s called.
Although Netty uses the `PooledByteBufAllocator` by default, this can be changed
easily via the `ChannelConfig` API or by specifying a different allocator when bootstrapping your application. More details can be found in chapter 8.

## Unpooled buffers

Netty provides a utility class called Unpooled, which provides static helper
methods to create unpooled ByteBuf instances. Table 5.8 lists the most important of
these methods.

## ByteBufUtil

- `hexdump()`
- `equals`

## ReferenceCounted

Note that a specific class can define its release-counting contract in its own unique
way. For example, we can envision a class whose implementation of `release()`always
sets the reference count to zero whatever its current value, thus invalidating all active
references at once.
**WHO IS RESPONSIBLE FOR RELEASE?**` In general, the last party to access an
object is responsible for releasing it. In chapter 6 we’ll explain the relevance
of this conept to ChannelHandler and ChannelPipeline.

## Summary

These are the main points we covered:

- The use of distinct read and write indices to control data access
- Different approaches to memory usage—backing arrays and direct buffers
- The aggregate view of multiple ByteBufs using CompositeByteBuf
- Data-access methods: searching, slicing, and copying
- The read, write, get, and set APIs
- ByteBufAllocator pooling and reference counting
