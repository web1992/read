# 第4章 连接管理

- TCP为HTTP提供了--条可靠的比特传输管道
- TCP流是分段的、由IP分组传送
- Http 的性能
- Connection首部
- 并行连接
- 持久连接
- HTTP/1.0+ "keep-alive” 连接
- HTTP/1.1“persistent” 连接
- Connection: keep-alive
- Keep- Alive和哑代理
- 盲中继 blind relay
- persistent connection
- Connection: close
- 管道化连接
- 如果一个事务，不管是执行一次还是很多次，得到的结果都相同，这个事务就是`幂等`的
- 完全关闭与半关闭
- TCP关闭及重置错误
- 将数据传送到已关闭连接时会产生“连接被对端重置”错误

## Http Https 网络协议栈

![http-ch-04-4-3.drawio.svg](./images/http-ch-04-4-3.drawio.svg)


## Http 的性能

- TCP连接的握手时延
- 延迟确认
- TCP 慢启动
- Nagle 算法与TCP_NODELAY
- TIME_WAIT 累积与端口耗尽

## Connection首部

Connection首部可以承载3种不同类型的标签，因此有时会很令人费解:
- HTTP首部字段名，列出了只与此连接有关的首部;
- 任意标签值，用于描述此连接的非标准选项;
- 值close,说明操作完成之后需关闭这条持久连接。


## http连接

- 并行连接
通过多条TCP连接发起并发的HTTP请求。
- 持久连接
重用TCP连接，以消除连接及关闭时延。
- 管道化连接
通过共享的TCP连接发起并发的HTTP请求。
- 复用的连接
交替传送请求和响应报文( 实验阶段)。

## 完全关闭与半关闭

应用程序可以关闭 TCP 输入和输出信道中的任意一个，或者将两者都关闭了。套接字调用 close() 会将 TCP 连接的输入和输出信道都关闭了。这被称作“完全关闭”，如图 4-20a 所示。还可以用套接字调用 shutdown() 单独关闭输入或输出信道。这被称为“半关闭”。
