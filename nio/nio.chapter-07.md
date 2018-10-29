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

## File Channels

```java
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
public class ChannelDemo
{
public static void main(String[] args) throws IOException
{
    RandomAccessFile raf = new RandomAccessFile("temp", "rw");
    FileChannel fc = raf.getChannel();
    long pos;
    System.out.println("Position = " + (pos = fc.position()));
    System.out.println("size: " + fc.size());
    String msg = "This is a test message.";
    ByteBuffer buffer = ByteBuffer.allocateDirect(msg.length() * 2);
    buffer.asCharBuffer().put(msg);
    fc.write(buffer);
    fc.force(true);
    System.out.println("position: " + fc.position());
    System.out.println("size: " + fc.size());
    buffer.clear();
    fc.position(pos);
    fc.read(buffer);
    buffer.flip();
    while (buffer.hasRemaining())
    System.out.print(buffer.getChar());
}
}

```

## Locking Files

```java
FileLock lock = fileChannel.lock();
try
{
// interact with the file channel
}
catch (IOException ioe)
{
// handle the exception
}
finally
{
lock.release();
}
```

## Socket Channels

- `ServerSocketChannel`
- `SocketChannel`
- `DatagramChannel`

Note Unlike buffers, which are not thread-safe, server socket channels, socket
channels, and datagram channels are thread-safe.

## Understanding Nonblocking Mode

`SelectableChannel`

```java
ServerSocketChannel ssc = ServerSocketChannel.open();
ssc.configureBlocking(false); // enable nonblocking mode
```

## Exploring Server Socket Channels

- static ServerSocketChannel open()
- ServerSocket socket()
- SocketChannel accept()

You create a new server socket channel by invoking the static open() factory
method. If all goes well, open() returns a ServerSocketChannel instance
associated with an unbound peer ServerSocket object. You can obtain this
object by invoking socket(), and then invoke ServerSocket’s bind() method
to bind the server socket (and ultimately the server socket channel) to a
specific address.
You can then invoke ServerSocketChannel’s accept() method to accept an
incoming connection. Depending on whether or not you have configured
the server socket channel to be nonblocking, this method either returns
immediately with null or a socket channel to an incoming connection, or
blocks until there is an incoming connection.

## Exploring Socket Channels

A socket channel behaves as a client in the TCP/IP stream protocol. You use
socket channels to initiate connections to listening servers.
Create a new socket channel by calling either of the open() methods.
Behind the scenes, a peer Socket object is created. Invoke SocketChannel’s
socket() method to return this peer object. Also, you can return the original
socket channel by invoking getChannel() on the peer Socket object.
A socket channel obtained from the noargument open() method isn’t
connected. Attempting to read from or write to this socket channel results in
java.nio.channels.NotYetConnectedException. To connect the socket, call
the connect() method on the socket channel or on its peer socket.
After a socket channel has been connected, it remains connected until
closed. To determine if a socket channel is connected, invoke
SocketChannel’s boolean isConnected() method.
The open() method that takes a java.net.InetSocketAddress argument also
lets you connect to another host at the specified remote address, as follows:

```java
SocketChannel sc = SocketChannel.open(new InetSocketAddress("localhost", 9999));
```

## Exploring Datagram Channels

> ChannelServer

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.DatagramChannel;
public class ChannelServer
{
final static int PORT = 9999;
public static void main(String[] args) throws IOException
{
System.out.println("server starting and listening on port " +
PORT + " for incoming requests...");
DatagramChannel dcServer = DatagramChannel.open();
dcServer.socket().bind(new InetSocketAddress(PORT));
ByteBuffer symbol = ByteBuffer.allocate(4);
ByteBuffer payload = ByteBuffer.allocate(16);
while (true)
{
payload.clear();
symbol.clear();
SocketAddress sa = dcServer.receive(symbol);
if (sa == null)
return;
System.out.println("Received request from " + sa);
String stockSymbol = new String(symbol.array(), 0, 4);
System.out.println("Symbol: " + stockSymbol);
if (stockSymbol.toUpperCase().equals("MSFT"))
{
payload.putFloat(0, 37.40f); // open share price
payload.putFloat(4, 37.22f); // low share price
payload.putFloat(8, 37.48f); // high share price
payload.putFloat(12, 37.41f); // close share price
}
else
{
payload.putFloat(0, 0.0f);
payload.putFloat(4, 0.0f);
payload.putFloat(8, 0.0f);
payload.putFloat(12, 0.0f);
}
dcServer.send(payload, sa);
}
}
}
```

> ChannelClient

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.DatagramChannel;
public class ChannelClient
{
final static int PORT = 9999;
public static void main(String[] args) throws IOException
{
if (args.length != 1)
{
System.err.println("usage: java ChannelClient stocksymbol");
return;
}
DatagramChannel dcClient = DatagramChannel.open();
ByteBuffer symbol = ByteBuffer.wrap(args[0].getBytes());
ByteBuffer response = ByteBuffer.allocate(16);
InetSocketAddress sa = new InetSocketAddress("localhost", PORT);
dcClient.send(symbol, sa);
System.out.println("Receiving datagram from " +
dcClient.receive(response));
System.out.println("Open price: " + response.getFloat(0));
System.out.println("Low price: " + response.getFloat(4));
System.out.println("High price: " + response.getFloat(8));
System.out.println("Close price: " + response.getFloat(12));
}
}
```

## Pipe

- `SourceChannel`
- `SinkChannel`