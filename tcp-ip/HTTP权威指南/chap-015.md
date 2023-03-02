# 第15章　实体和编码

- 分块编码（chunked encoding）
- Content-Length 首部
- 实体摘要 Content-MD5
- 文本的字符编码 Content-Type: text/html; charset=iso-8859-4
- Content-Type: multipart/form-data; boundary=[abcdefghijklmnopqrstuvwxyz]


> HTTP 还会确保它的报文被正确传送、识别、提取以及适当处理。

- 可以被正确地识别（通过 Content-Type 首部说明媒体格式，Content-Language 首部说明语言），以便浏览器和其他客户端能正确处理内容。
- 可以被正确地解包（通过 Content-Length 首部和 Content-Encoding 首部）。
- 是最新的（通过实体验证码和缓存过期控制）
- 符合用户的需要（基于 Accept 系列的内容协商首部）
- 在网络上可以快速有效地传输（通过范围请求、差异编码以及其他数据压缩方法）
- 完整到达、未被篡改（通过传输编码首部和 Content-MD5 校验和首部）

## HTTP 实体首部

HTTP/1.1 版定义了以下 10 个基本字体首部字段。

Content-Type
实体中所承载对象的类型。

Content-Length
所传送实体主体的长度或大小。

Content-Language
与所传送对象最相配的人类语言。

Content-Encoding
对象数据所做的任意变换（比如，压缩）。

Content-Location
一个备用位置，请求时可通过它获得对象。

Content-Range
如果这是部分实体，这个首部说明它是整体的哪个部分。

Content-MD5
实体主体内容的校验和。

Last-Modified
所传输内容在服务器上创建或最后修改的日期时间。

Expires
实体数据将要失效的日期时间。

Allow
该资源所允许的各种请求方法，例如，GET 和 HEAD。

ETag 这份文档特定实例（参见 15.7 节）的唯一验证码。ETag 首部没有正式定义为实体首部，但它对许多涉及实体的操作来说，都是一个重要的首部。

Cache-Control
指出应该如何缓存该文档。和 ETag 首部类似，Cache-Control 首部也没有正式定义为实体首部。


## 1　常用媒体类型


表15-1　常用媒体类型

媒体类型	描　　述
- text/html	实体主体是 HTML 文档
- text/plain	实体主体是纯文本文档
- image/gif	实体主体是 GIF 格式的图像
- image/jpeg	实体主体是 JPEG 格式的图像
- audio/x-wav	实体主体包含 WAV 格式声音数据
- model/vrml	实体主体是三维的 VRML 模型
- application/vnd.ms-powerpoint	实体主体是 Microsoft PowerPoint 演示文档
- multipart/byteranges	实体主体有若干部分，每个部分都包含了完整文档中不同的字节范围
- message/http	实体主体包含完整的 HTTP 报文（参见 TRACE）