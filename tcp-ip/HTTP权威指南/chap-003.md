# 第3章Http报文

概念：

- 报文是如何流动的;
- HTTP报文的三个组成部分(起始行、首部和实体的主体部分);
- 请求和响应报文之间的区别;
- 请求报文支持的各种功能(方法);
- 和响应报文一起返回的各种状态码;
- 各种各样的HTTP首部都是用来做什么的。


- 起始行 start line
- 首部 header
- 主体 body
- ASCII 字符
- CRLF
- ASCII 13 
- ASCII 10
- 请求报文(request message)
- 响应报文 (response message)
- HTTP/x.y 版本号

## 报文格式

- 请求报文
```
<method> <request url> <version>
<headers>

<entiry body>
```

- 响应报文

```
<version> <status> <reason-phrase>
<headers>

<entiry body>
```

## 状态码

- 状态码分类

|整体范围|自定义范围|分类|
|-------|--------|----|
|100 ~ 199 | 100 ~ 101 | 信息提示
|200 ~ 299 | 200 ~ 206 | 成功
|300 ~ 399 | 300 ~ 305 | 重定向
|400 ~ 499 | 400 ~ 415 | 客户端错误
|500 ~ 599 | 500 ~ 505 | 服务器错误

> 常见状态码

200 401 404
