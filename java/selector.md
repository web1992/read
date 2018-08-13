# Selector

## server and client

```java
/**
* 服务端
*/
public class SSC {

    private static final Integer PORT = 9999;
    static ByteBuffer bb = ByteBuffer.allocateDirect(8);

    public static void main(String[] args) throws IOException {

        ServerSocketChannel ssc = ServerSocketChannel.open();
        ssc.bind(new InetSocketAddress(PORT));
        System.out.println("server start at port: " + PORT);
        // config no blocking
        ssc.configureBlocking(false);

        Selector selector = Selector.open();

        ssc.register(selector, SelectionKey.OP_ACCEPT);

        while (true) {
            int num = selector.select();

            if (0 == num) {
                System.out.println("no invalid selector");
                continue;
            }

            Set<SelectionKey> selectionKeys = selector.selectedKeys();
            Iterator<SelectionKey> iterator = selectionKeys.iterator();

            while (iterator.hasNext()) {
                SelectionKey selectionKey = iterator.next();

                if (selectionKey.isAcceptable()) {
                    SocketChannel sc = ((ServerSocketChannel)(selectionKey.channel())).accept();

                    if (null == sc) {
                        continue;
                    }

                    bb.clear();
                    bb.putLong(new Date().getTime());
                    bb.flip();

                    while (bb.hasRemaining()) {
                        sc.write(bb);
                    }

                    sc.close();

                    iterator.remove();
                }
            }
        }

    }
    /**
    * 客户端
    */
    static class Client {

        public static void main(String[] args) throws IOException {

            SocketChannel sc = SocketChannel.open();

            sc.connect(new InetSocketAddress("localhost", PORT));

            long time = 0;

            while (sc.read(bb) != -1) {
                bb.flip();

                while (bb.hasRemaining()) {
                    time <<= 8;
                    time |= bb.get() & 255;
                }
                bb.clear();
            }

            sc.close();
            System.out.println("get time from server: " + new Date(time));
        }
    }

}
```