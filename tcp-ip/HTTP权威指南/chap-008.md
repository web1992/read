# 第8章　集成点：网关、隧道及中继

- 网关（gateway）
- 有些网关会自动将 HTTP 流量转换为其他协议
- 服务器端网关（server-side gateway）通过 HTTP 与客户端对话，通过其他协议与服务器通信（HTTP/*）。
- 客户端网关（client-side gateway）通过其他协议与客户端对话，通过 HTTP 与服务器通信（*/HTTP）
- 协议网关
- < 客户端协议 >/< 服务器端协议 >
- 用CONNECT建立HTTP隧道
- 隧道 传输非HTTP 流量
- HTTP 中继（relay）
- 对流量进行盲转发
