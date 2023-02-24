# 第11章　客户端识别与 cookie 机制

- 个性化接触
- 用户识别机制
- WWW-Authenticate 首部和 Authorization
- 网络地址转换（Network Address Translation，NAT）
- Client-IP 或 X-Forwarded-For 扩展首部来保存原始的 IP 地址
- 401 Login Required
- 改动后包含了用户状态信息的 URL 被称为胖 URL（fat URL）
- cookie
- 会话 cookie 和持久 cookie
- Set-Cookie 或 Set-Cookie2 HTTP 响应（扩展）首部
- 客户端侧状态（client-side state）
- cookie 规范的正式名称为 HTTP 状态管理机制（HTTP state management mechanism）。
- Cookie: session-id=002-1145265-8016838; session-id-time=1007884800
- Set-Cookie2 首部和 Cookie2 首部，

## 用户识别机制

- 承载用户身份信息的 HTTP 首部。
- 客户端 IP 地址跟踪，通过用户的 IP 地址对其进行识别。
- 用户登录，用认证方式来识别用户。
- 胖 URL，一种在 URL 中嵌入识别信息的技术。
- cookie，一种功能强大且高效的持久身份识别技术。

## HTTP首部

表11-1　承载用户相关信息的HTTP首部

|首部名称|	首部类型|	描　　述 |
|-------|---------|----------|
From	        |请求	|用户的 E-mail 地址
User-Agent      |请求	|用户的浏览器软件
Referer         |请求	|用户是从这个页面上依照链接跳转过来的
Authorization   |请求	|用户名和密码（稍后讨论）
Client-IP	    |扩展（请求）	|客户端的 IP 地址（稍后讨论）
X-Forwarded-For	|扩展（请求）	|客户端的 IP 地址（稍后讨论）
Cookie	        |扩展（请求）	|服务器产生的 ID 标签（稍后讨论

## Cookie

会话 cookie 和持久 cookie 之间唯一的区别就是它们的过期时间。稍后我们会看到，如果设置了 Discard 参数，或者没有设置 Expires 或 Max-Age 参数来说明扩展的过期时间，这个 cookie 就是一个会话 cookie。

```cookie
# Netscape HTTP Cookie File
# http://www.netscape.com/newsref/std/cookie_spec.html
# This is a generated file! Do not edit.
#
# domain                 allh  path     secure expires     name        value
　
www.fedex.com            FALSE /        FALSE  1136109676  cc          /us/
.bankofamericaonline.com TRUE  /        FALSE  1009789256  state       CA
.cnn.com                 TRUE  /        FALSE  1035069235  SelEdition  www
secure.eepulse.net       FALSE /eePulse FALSE  1007162968  cid         %FE%FF%002
www.reformamt.org        TRUE  /forum   FALSE  1033761379  LastVisit   1003520952
www.reformamt.org        TRUE  /forum   FALSE  1033761379  UserName    Guest
```

文本文件中的每一行都代表一个 cookie。有 7 个用 tab 键分隔的字段。

|字段|含义 |
|----|----|
|domain（域） |cookie 的域。
|allh|是域中所有的主机都获取 cookie，还是只有指定了名字的主机获取。
|path（路径）|域中与 cookie 相关的路径前缀。
|secure（安全）|是否只有在使用 SSL 连接时才发送这个 cookie。
|expiration（过期）|从格林尼治标准时间 1970 年 1 月 1 日 00:00:00 开始的 cookie 过期秒数。
|name（名字）|cookie 变量的名字。
|value（值）|cookie 变量的值。

## cookie 隐私

很多 Web 站点都会与第三方厂商达成协议，由其来管理广告。这些广告被做得像 Web 站点的一个组成部分，而且它们确实发送了持久 cookie。用户访问另一个由同一广告公司提供服务的站点时，（由于域是匹配的）浏览器就会再次回送早先设置的持久 cookie。营销公司可以将此技术与 Referer 首部结合，暗地里构建一个用户档案和浏览习惯的详尽数据集。现代的浏览器都允许用户对隐私特性进行设置，以限制第三方 cookie 的使用。

