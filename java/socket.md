# socket

## ServerSocketChannel

demo

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;

/**
 * server
 */
public class SSC {
    public static void main(String[] args) throws IOException, InterruptedException {

        System.out.println("start service...");
        ServerSocketChannel ssc = ServerSocketChannel.open();

        ssc.socket().bind(new InetSocketAddress(9999));
        ssc.configureBlocking(false);

        String msg = "Hello I am server";
        ByteBuffer byteBuffer = ByteBuffer.wrap(msg.getBytes());
        while (true) {
            SocketChannel sc = ssc.accept();

            if (sc != null) {
                System.out.println();
                System.out.println("receive connect form " + sc.socket().getRemoteSocketAddress());
                byteBuffer.rewind();
                sc.write(byteBuffer);
                sc.close();
            } else {
                Thread.sleep(1000);
            }
        }


    }
}

/**
 * client
 */
class SC {
    public static void main(String[] args) throws IOException {
        SocketChannel sc = SocketChannel.open();
        sc.configureBlocking(false);

        sc.connect(new InetSocketAddress("localhost", 9999));

        while (!sc.finishConnect()) {
            System.out.println("waiting to finished...");
        }


        ByteBuffer buffer = ByteBuffer.allocate(200);

        while (sc.read(buffer) >= 0) {
            buffer.flip();
            while (buffer.hasRemaining()) {
                System.out.print((char) buffer.get());
            }
            buffer.clear();
        }
        sc.close();

    }
}
```