# 第12章　基本认证机制

- 基本认证（basic authentication）
- 摘要认证（digest authentication）
- 质询 / 响应（challenge/response）框架
- 代理认证（proxy authentication）
- Base-64 (用户名:密码)

## 表12-3　Web服务器与代理认证

- Web服务器	代理服务器
- Unauthorized status code: 401	Unauthorized status code: 407
- WWW-Authenticate	Proxy-Authenticate
- Authorization	Proxy-Authorization
- Authentication-Info	Proxy-Authentication-Info
