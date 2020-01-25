# redis 笔记

## Other

- zset
- set
- hashset
- intset
- list
- ziplist
- linklist

## redis 的数据结构

- SDS
- listNode
  - list
- dict
  - dicEntry
  - dicht
- intset
- skiplist
- ziplist
- redisObject
  - REDIS_STRING
  - REDIS_LIST
  - REDIS_HASH
  - REDIS_SET
  - REDIS_ZSET

| 类型常量     | 对象的名称   |
| ------------ | ------------ |
| REDIS_STRING | 字符串对象   |
| REDIS_LIST   | 列表对象     |
| REDIS_HASH   | 哈希对象     |
| REDIS_SET    | 集合对象     |
| REDIS_ZSET   | 有序集合对象 |

## redis 命令与对象类型

- SET SGET APPEND STRLEN 字符串
- HDEL HSET HGET HLEN 哈希
- RPUSH LPOP LINSERT LLEN 列表
- SADD SPOP SINSERT SCARD 集合
- ZADD ZCARD ZRANK SZCORE 有序集合

## redis 数据库

- 数据库切换
- 过期建删除策略

## redis RDB

二进制的文件的持久化，根据 redis 不同的对象使用不同的数据对象格式进行保存

## redis AOF

基于 redis 命令的持久化文件，基于redis 命令会导致文件过大，redis 提了 AOF 重写功能，缩小文件的大小

## redis 事件

## redis 排序

## redis bit array
