# CHAPTER 5

## ByteBuf

ByteBuf—Netty’s data container

## api

- `ByteBuf` abstract class
- `ByteBufHolder` interface

These are some of the advantages of the ByteBuf API:
■ It’s extensible to user-defined buffer types.
■ Transparent zero-copy is achieved by a built-in composite buffer type.
■ Capacity is expanded on demand (as with the JDK StringBuilder).
■ Switching between reader and writer modes doesn’t require calling ByteBuffer’s
flip() method.
■ Reading and writing employ distinct indices.
■ Method chaining is supported.
■ Reference counting is supported.
■ Pooling is supported.