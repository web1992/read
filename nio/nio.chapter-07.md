# Chapter 7 Channels

## Introducing Channels

A channel is an object that represents an open connection to a hardware
device, a file, a network socket, an application component, or another entity
that’s capable of performing writes, reads, and other I/O operations.
`Channels` efficiently transfer data between byte buffers and operating
system-based I/O service sources or destinations.

- `WritableByteChannel`
- `ReadableByteChannel`

```java
package cn.web1992.utils.demo.nio;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.nio.channels.WritableByteChannel;

public class ChannelDemo {
    public static void main(String[] args) {
        ReadableByteChannel src = Channels.newChannel(System.in);
        WritableByteChannel dest = Channels.newChannel(System.out);
        try {
            copy(src, dest); // or copyAlt(src, dest);
        } catch (IOException ioe) {
            System.err.println("I/O error: " + ioe.getMessage());
        } finally {
            try {
                src.close();
                dest.close();
            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
        }
    }

    static void copy(ReadableByteChannel src, WritableByteChannel dest)
            throws IOException {
        ByteBuffer buffer = ByteBuffer.allocateDirect(2048);
        while (src.read(buffer) != -1) {
            buffer.flip();
            dest.write(buffer);
            buffer.compact();
        }
        buffer.flip();
        while (buffer.hasRemaining())
            dest.write(buffer);
    }

    static void copyAlt(ReadableByteChannel src, WritableByteChannel dest)
            throws IOException {
        ByteBuffer buffer = ByteBuffer.allocateDirect(2048);
        while (src.read(buffer) != -1)

        {
            buffer.flip();
            while (buffer.hasRemaining())
                dest.write(buffer);
            buffer.clear();
        }
    }
}
```

The demo presents two approaches to copying bytes from the standard
input stream to the standard output stream. In the first approach, which is
exemplified by the copy() method, the goal is to minimize operating system
I/O calls (via the write() method calls), although more data may end up
being copied as a result of the compact() method calls. In the second
approach, as demonstrated by copyAlt(), the goal is to eliminate data
copying, although more operating system I/O calls might occur.
The copy() and copyAlt() methods first allocate a direct byte buffer (recall
that a direct byte buffer is the most efficient means for performing I/O on
the Java virtual machine [JVM]) and enter a while loop that continually
reads bytes from the source channel until end-of-input (read() returns -1).
Following the read, the buffer is where the methods diverge.

- The copy() method while loop makes a single call to
  write(). Because write() might not completely drain
  the buffer, compact() is called to compact the buffer
  before the next read. Compaction ensures that unwritten
  buffer content isn’t overwritten during the next read
  operation. Following the while loop, copy() flips the
  buffer in preparation for draining any remaining content,
  and then works with hasRemaining() and write() to
  completely drain the buffer.
- The copyAlt() method while loop contains a nested
  while loop that works with hasRemaining() and write()
  to continue draining the buffer until the buffer is empty.
  This is followed by a clear() method call, which
  empties the buffer so that it can be filled on the next
  read() call.

_Note_ It’s important to realize that a single write() method call may not
output the entire content of a buffer. Similarly, a single read() call may not
completely fill a buffer.

## Scatter/Gather I/O
