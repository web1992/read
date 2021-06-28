# TCP

## TCP 连接的定义

一个TCP连接 = 一个Socket + 窗口大小  + 序列号

Socket = 一个IP地址+一个端口号

```doc
The reliability and flow control mechanisms described above require that TCPs initialize and maintain certain status information for each data stream. The combination of this information, including sockets, sequence numbers, and window sizes, is called a connection.
```
