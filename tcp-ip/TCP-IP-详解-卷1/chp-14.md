# DNS：域名系统

在一个应用程序请求TCP打开一个连接或使用
UDP发送一个数据报之前。心须将一个主机名转换为一个IP地址。操作系统内核中的TCP/IP
协议族对于DNS一点都不知道。

RFC1034 说明了DNS的概念和功能，RFC1035 详细说明了DNS的规范和实现

- DNS的层次组织
- DNS查询报文中的问题部分
- DNS响应报文中的资源记录部分
- gethostbyname
- gethostbyaddr
- 指针查询

> 图14-3 DNS查询和响应的一般格式

![TCP-IP-14-3.png](./images/TCP-IP-14-3.png)
