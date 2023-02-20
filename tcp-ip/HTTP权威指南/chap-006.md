# 第6章　代理

- Http 代理
- 代理与网关的对比
- 代理做协议的转发 http -> http
- 网关做协议的转发+转化 Http -> POP
- 代理使用同一种协议，网关则将不同的协议连接起来
- 反向代理
- 内容路由器
- 反向代理
- 转码器
- 客户端代理配置：PAC文件
- Via 首部
- TRACE 方法
- Max-Forwards
- OPTIONS

Web 代理（proxy）服务器是网络的中间实体。代理位于客户端和服务器之间，扮演“中间人”的角色，在各端点之间来回传送 HTTP 报文。

## 反向代理

代理可以假扮 Web 服务器。这些被称为替代物（surrogate）或反向代理（reverse proxy）的代理接收发给 Web 服务器的真实请求，但与 Web 服务器不同的是，它们可以发起与其他服务器的通信，以便按需定位所请求的内容。

## 客户端代理配置PAC文件

FindProxyForURL的返回值	描　　述
DIRECT	不经过任何代理，直接进行连接
PROXY host:port	应该使用指定的代理
SOCKS host:port	应该使用指定的 SOCKS 服务器