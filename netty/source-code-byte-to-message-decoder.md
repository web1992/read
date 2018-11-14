# ByteToMessageDecoder

Netty 中负责把字节流转化成一个具体对象的基类

> 来自Netty docs:

Generally frame detection should be handled earlier in the pipeline by adding a `DelimiterBasedFrameDecoder`, `FixedLengthFrameDecoder`, `LengthFieldBasedFrameDecoder`, or `LineBasedFrameDecoder`.

If a custom frame decoder is required, then one needs to be careful when implementing one with `ByteToMessageDecoder`. Ensure there are enough bytes in the buffer for a complete frame by checking `ByteBuf.readableBytes()`. If there are not enough bytes for a complete frame, return without modifying the reader index to allow more bytes to arrive.

To check for complete frames without modifying the reader index, use methods like ByteBuf.getInt(int). One MUST use the reader index when using methods like `ByteBuf.getInt(int)`. For example `calling in.getInt(0)` is assuming the frame starts at the beginning of the buffer, which is not always the case. Use `in.getInt(in.readerIndex())` instead.