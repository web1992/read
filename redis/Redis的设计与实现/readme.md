# redis 笔记

《Redis 的设计与实现》笔记

- [redis 笔记](#redis-笔记)
  - [redis 的数据结构](#redis-的数据结构)
  - [redis 命令与对象类型](#redis-命令与对象类型)
  - [redis 数据库](#redis-数据库)
  - [redis RDB](#redis-rdb)
  - [redis AOF](#redis-aof)
  - [redis 事件](#redis-事件)
  - [redis 排序](#redis-排序)
  - [redis bit array](#redis-bit-array)
  - [redis 复制](#redis-复制)
  - [redis Sentinel](#redis-sentinel)
  - [redis 集群(Cluster)](#redis-集群cluster)
  - [redis 发布和订阅](#redis-发布和订阅)
  - [redis 事务](#redis-事务)
  - [redis 的 Java 客户端](#redis-的java-客户端)

## redis 的数据结构

- SDS
- listNode
  - list
- dict
  - dicEntry
  - dicht
- intset6
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

基于 redis 命令的持久化文件，基于 redis 命令会导致文件过大，redis 提了 AOF 重写功能，缩小文件的大小

## redis 事件

- serverCron

## redis 排序

## redis bit array

- 用来进行数据统计使用
- 汉明重量算法 统计

## redis 复制

PSYNC 的实现步骤

- 设置主服务器的 IP 和端口
- 建立套字节连接
- 发送 PING
- 身份验证
- 发生端口信息
- 同步
- 命令传播

## redis Sentinel

- Sentinel 用来进行 Redis 的故障转移
- 如何检查服务的下线（每 1 秒发送一次 PING 命令）
- 主观下线 （Sentinel 在指定的时间内没有收到 PING 回复）
- 客观下线 （Sentinel 询问其他 Sentinel 是否需要下线此服务器）
- 进行 Sentinel 选举，选择出一个领头的 Sentinel
- 领头的 Sentinel 对下线的 Redis master 下线，找到一个新的 slave 当做 master 并让其他 savle 复制这个新的 master

Sentinel 本质是一种特殊的 Redis 服务器

## redis 集群(Cluster)

- 集群分槽 16384 个 slot（槽）
- 集成也支持主从模式（集群的主从模式）

## redis 发布和订阅

| 支持的命令      | 描述                                  |
| --------------- | ------------------------------------- |
| PUBLISH         | 发布                                  |
| SUBSCRIBE       | 频道订阅                              |
| UNSUBSCRIBE     | 取消订阅                              |
| PSUBSCRIBE      | 模式订阅（支持通配符的订阅）          |
| PSUNSUBCRIBE    | 取消订阅                              |
| PUBSUB CHANNELS | 查询订阅信息(只会列出 SUBSCRIBE 订阅) |
| PUBSUB NUMSUB   | 统计 SUBSCRIBE 订阅者的数量           |
| PUBSUB NUMPAT   | 统计 PSUBSCRIBE 订阅者的数量          |

```c
struct redisServer{

// 保存所有订阅的频道(字典)
dict *pubsub_channels;

// 保存所有模式的订阅关系（列表）
// PSUBSCRIBE 命令
// 的执行订阅信息就保存在这里
list *pusbub_patterns;
}

typedef struct pubsubPattern{
// 订阅模式的客户端
redisClient *client;
// 被订阅的模式
robj *pattern;
}
```

## redis 事务

事务提供了一种将多个命令请求打包，然后一次性，按顺序执行地执行多个命令的机制，并且在事务执行期间，
服务器不会中断事务而改去执行其他客户端的命令请求，它会将事务中的所有命令都执行完毕，然后才去处理其他客户端的命令请求。

| 事务命令 | 描述                                         |
| -------- | -------------------------------------------- |
| MULTI    | 事务开始                                     |
| EXEC     | 事务执行                                     |
| WATCH    | 在执行 EXEC 之前检查被监视的键是否被修改过了 |
| DISCARD  |

> 事务的实现

1. 事务开始 MULTI 让客户端进入事务状态
2. 命令入队
3. 事务执行

```c
typedef struct redisClient{
    // 事务状态
    multiState mstate;
} redisClient;

typedef struct multiState{
    // 事务队列，FIFO顺序
    multiCmd *commands;
    // 已入队命令技术
    int count;
} multiState;

typedef struct multiCmd{
    // 参数
    robj **argv;
    // 参数数量
    int argc;
    // 命令指针
    struct redisCommand *cmd;
} multiCmd;
```

> 事务的 ACDI

在 Redis 中，事务总是具有原子性(Atomiccity)，一致性(Consistency)和隔离性(Isolation)，并且当 Redis 运行在某种特定的持久模式下时，事务也具有耐久性(Durablity)。

## redis 的 Java 客户端

- [jedis](jedis.md)
