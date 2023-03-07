# 第20章　重定向与负载均衡

-  NAT（Network Address Translation，网络地址转换）（IP地址转发）
- 完全 NAT（full NAT）
- 半 NAT（half NAT）
- NECP（Network Element Control Protocol，网元控制协议）
- WPAD（Web 代理自动发现协议）
- ICP（因特网缓存协议）
- CARP（缓存阵列路由协议）
- HTCP（超文本缓存协议

我们会学习下列重定向技术，它们是如何工作的以及它们的负载均衡能力如何（如果有的话）：

- HTTP 重定向；
- DNS 重定向；
- 任播路由；
- 策略路由；
- IP MAC 转发；
- IP 地址转发；
- WCCP（Web 缓存协调协议）；
- ICP（缓存间通信协议）；
- HTCP（超文本缓存协议）；
- NECP（网元控制协议）；
- CARP（缓存阵列路由协议）；
- WPAD（Web 代理自动发现协议）


## 其他基于DNS的重定向算法

- 负载均衡算法
有些 DNS 服务器会跟踪 Web 服务器上的负载，将负载最轻的 Web 服务器放在列表的最前面。

- 邻接路由算法
Web 服务器集群在地理上分散时，DNS 服务器会尝试着将用户导向最近的 Web 服务器。

- 故障屏蔽算法
DNS 服务器可以监视网络的状况，并将请求绕过出现服务中断或其他故障的地方。

## PAC 

PAC 文件是个 JavaScript 文件，其中必须定义函数：
```js
function FindProxyForURL(url, host)
```

```js
return_value = FindProxyForURL(url_of_request, host_in_url);
```