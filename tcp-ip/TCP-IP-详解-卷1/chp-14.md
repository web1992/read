# DNS：域名系统

在一个应用程序请求TCP打开一个连接或使用
UDP发送一个数据报之前。心须将一个主机名转换为一个IP地址。操作系统内核中的TCP/IP
协议族对于DNS一点都不知道。

RFC1034 说明了DNS的概念和功能，RFC1035 详细说明了DNS的规范和实现

- DNS的层次组织
- FQDN (Full Qualified Domain Name）
- DNS查询报文中的问题部分
- DNS响应报文中的资源记录部分 RR（Resource Record）
- gethostbyname
- gethostbyaddr
- 指针查询

> 指针查询

DNS中一直难于理解的部分就是指针查询方式，即给定一个IP地址，返回与该地址对应的域名

但应牢记的是DNS名字是由DNS树的底部逐步向上书写的。这意味着
对于IP地址为140.252.13.33的sun主机，它的DNS名字为33.13.252.140.in-addr.arpa。

> 资源记录

- A
- PTR
- CNAME
- HINFO
- MX

> 图14-3 DNS查询和响应的一般格式

![TCP-IP-14-3.png](./images/TCP-IP-14-3.png)
