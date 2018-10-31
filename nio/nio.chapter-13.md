# Chapter 13 Asynchronous I/O

## Multiplexed

`Note` Multiplexed I/O is often used with operating systems that offer highly
scalable and performant polling interfaces—Linux and Solaris are examples.
Asynchronous I/O is often used with operating systems that provide highly
scalable and performant asynchronous I/O facilities—newer Windows operating
systems come to mind.

## AsynchronousChannel

`CompletionHandler`

`void completed(V result, A attachment)`: Called when
the operation completes successfully. The operation’s
result is identified by result and the object attached to
the operation when it was initiated is identified by
attachment.
`void failed(Throwable t, A attachment)`: Called
when the operation fails. The reason why the operation
failed is identified by t and the object attached to the
operation when it was initiated is identified by attachment.

```java
public interface CompletionHandler<V,A> {
    void completed(V result, A attachment);
    void failed(Throwable exc, A attachment);
}
```

`Future<Integer> read(ByteBuffer dst)`: Read a
sequence of bytes from this channel into the byte buffer.
Return a Future to access the bytes when available.
`<A> void read(ByteBuffer dst, A attachment, CompletionHandler<Integer,? super A> handler)`:
Read a sequence of bytes from this channel into the
byte buffer. Access the bytes in the CompletionHandler.
`Future<Integer> write(ByteBuffer src)`: Write a
sequence of bytes to this channel from the byte buffer.
Return a Future to access the write count when available.
`<A> void write(ByteBuffer src, A attachment, CompletionHandler<Integer,? super A> handler)`:
Write a sequence of bytes to this channel from the byte
buffer. Access the write count in the CompletionHandler.

## Asynchronous File Channels

```java
AsynchronousFileChannel ch;
ch = AsynchronousFileChannel.open(Paths.get("somefile"));
```

> demo

```java
java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.AsynchronousFileChannel;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.concurrent.Future;
    public static void main(String[] args) throws Exception
    {
        if (args.length != 1)
        {
            System.err.println("usage: java AFCDemo path");
            return;
        }
        Path path = Paths.get(args[0]);
        AsynchronousFileChannel ch = AsynchronousFileChannel.open(path);
        ByteBuffer buf = ByteBuffer.allocate(1024);
        Future<Integer> result = ch.read(buf, 0);
        while (!result.isDone())
        {
            System.out.println("Sleeping...");
            Thread.sleep(500);
        }
        System.out.println("Finished = " + result.isDone());
        System.out.println("Bytes read = " + result.get());
        ch.close();
    }
}
```

> demo2

```java
import java.nio.ByteBuffer;
import java.nio.channels.AsynchronousFileChannel;
import java.nio.channels.CompletionHandler;
import java.nio.file.Path;
import java.nio.file.Paths;

public class AFCDemo {
    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println("usage: java AFCDemo path");
            return;
        }
        Path path = Paths.get(args[0]);
        AsynchronousFileChannel ch = AsynchronousFileChannel.open(path);
        ByteBuffer buf = ByteBuffer.allocate(1024);
        Thread mainThd = Thread.currentThread();
        ch.read(buf, 0, null,
                new CompletionHandler<Integer, Void>() {
                    @Override
                    public void completed(Integer result, Void v) {
                        System.out.println("Bytes read = " + result);
                        mainThd.interrupt();
                    }

                    @Override
                    public void failed(Throwable t, Void v) {
                        System.out.println("Failure: " + t.toString());
                        mainThd.interrupt();
                    }
                });
        System.out.println("Waiting for completion");
        try {
            mainThd.join();
        } catch (InterruptedException ie) {
            System.out.println("Terminating");
        }
        ch.close();
    }
}
```

## Asynchronous Socket Channels
