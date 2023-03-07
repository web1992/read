# 第21章　日志记录与使用情况跟踪

## 常用日志格式字段

|字　　段|	描　　述|
|-------|--------|
|remotehost	    |请求端机器的主机名或 IP 地址（如果没有配置服务器去执行反向 DNS 或无法查找请求端的主机名，就使用 IP 地址）
|username	    |如果执行了 ident 查找，就是请求端已认证的用户名a
|auth-username	|如果进行了认证，就是请求端已认证的用户名
|timestamp	    |请求的日期和时间
|request-line	|精确的 HTTP 请求行文本， GET /index.html HTTP/1.1
|response-code	|响应中返回的 HTTP 状态码
|response-size	|响应主体中的 Content-Length，如果响应中没有返回主体，就记录0