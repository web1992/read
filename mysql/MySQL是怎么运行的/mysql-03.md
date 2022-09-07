# 第3章 乱码的前世今生-字符集和比较规则

- utf8mb3 ：阉割过的 utf8 字符集，只使用1～3个字节表示字符。
- utf8mb4 ：正宗的 utf8 字符集，使用1～4个字节表示字符。
- 字符集和比较规则
- 字符集 指的是某个字符范围的编码规则。
- 比较规则 是针对某个字符集中的字符比较大小的一种规则。
- SHOW CHARSET;
- SHOW COLLATION LIKE 'utf8\_%';
- character_set_server 表示服务器级别的字符集， collation_server 表示服务器级别的比较规则
- character_set_client
- character_set_connection
