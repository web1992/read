# Socket 基础

建议阅读 《Uninx 网络编程卷 1》 这本书，对 Unix 网络编程有很详细的介绍。

## 服务器的创建

```java
// sun.nio.ch.ServerSocketChannelImpl
ServerSocketChannelImpl(SelectorProvider var1) throws IOException {
    super(var1);
    this.fd = Net.serverSocket(true);
    this.fdVal = IOUtil.fdVal(this.fd);
    this.state = 0;
}

// bind
public ServerSocketChannel bind(SocketAddress var1, int var2) throws IOException {
    Net.bind(this.fd, var4.getAddress(), var4.getPort());
    Net.listen(this.fd, var2 < 1 ? 50 : var2);
}

```

```sh
# 执行 Net.bind 之后
➜  ~ lsof -i:8007
COMMAND  PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
java    4691   zl   95u  IPv6 0xe3ebd2dd6f674cc5      0t0  TCP *:8007 (CLOSED)
# 执行 Net.listen 之后
➜  ~ lsof -i:8007
COMMAND  PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
java    4691   zl   95u  IPv6 0xe3ebd2dd6f674cc5      0t0  TCP *:8007 (LISTEN)
➜  ~
```

上面的 TCP 状态从 `CLOSED` -> `LISTEN`

## 客户端的创建
