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

## redis RDB

## redis AOF

## redis 排序

## redis bit array
