# Bootstrap

## ServerBootstrap

服务器`ServerBootstrap`初始化过程

类的继承关系

![ServerBootstrap](./images/ServerBootstrap.png)

1. 初始化 group
2. 初始化 channelFactory
3. initAndRegister
4. 初始化 Channel,包含二个步骤 initAndRegister

## AbstractNioChannel

```java
    protected AbstractNioChannel(Channel parent, SelectableChannel ch, int readInterestOp) {
        super(parent);
        this.ch = ch;
        this.readInterestOp = readInterestOp;
        try {
            ch.configureBlocking(false);
        } catch (IOException e) {
            try {
                ch.close();
            } catch (IOException e2) {
                if (logger.isWarnEnabled()) {
                    logger.warn(
                            "Failed to close a partially initialized socket.", e2);
                }
            }

            throw new ChannelException("Failed to enter non-blocking mode.", e);
        }
    }
```