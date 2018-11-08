# CHAPTER 5

## ByteBuf

`ByteBuf`—Netty’s data container

## api

- `ByteBuf` abstract class
- `ByteBufHolder` interface

These are some of the advantages of the ByteBuf API:

- It’s extensible to user-defined buffer types.
- Transparent zero-copy is achieved by a built-in composite buffer type.
- Capacity is expanded on demand (as with the JDK StringBuilder).
- Switching between reader and writer modes doesn’t require calling ByteBuffer’s flip() method.
- Reading and writing employ distinct indices.
- Method chaining is supported.
- Reference counting is supported.
- Pooling is supported.

## ByteBufHolder

ByteBufHolder is a good choice if you want to implement a message object that stores
its payload in a ByteBuf.

## ByteBufAllocator

- `PooledByteBufAllocator`
- `UnpooledByteBufAllocator`

## Unpooled buffers

Netty provides a utility class called Unpooled, which provides static helper
methods to create unpooled ByteBuf instances. Table 5.8 lists the most important of
these methods.

## ByteBufUtil

- `hexdump()`
- `equals`

## ReferenceCounted

## Summary

These are the main points we covered:

- The use of distinct read and write indices to control data access
- Different approaches to memory usage—backing arrays and direct buffers
- The aggregate view of multiple ByteBufs using CompositeByteBuf
- Data-access methods: searching, slicing, and copying
- The read, write, get, and set APIs
- ByteBufAllocator pooling and reference counting
