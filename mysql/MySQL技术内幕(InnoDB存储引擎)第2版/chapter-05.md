# 第5章 索引与算法

- B+树索引
- 全文索引
- 哈希索引
- AVL 树，平衡二叉树
- 聚集索引(clustered inex)和辅助索引(secondary inex)
- Fast Index Creation
- Online DDL
- innodb_online_alter_log_max_size
- Cardinality 值的采样更新
- 覆盖索引
- FORCE INDEX
- Multi-Range Read 优化

## B+树

B+树是为磁盘或其他直接存取辅助设备设计的一种平衡查找树。在B+树中，所有记录节点都是按键值的大小顺序存放在同一层的叶子节点上，由各叶子节点指针进行连接.

![mysql-innodb-chapter-05-06.drawio.svg](./images/mysql-innodb-chapter-05-06.drawio.svg)

## 聚集索引

InnoDB存储引擎表是索引组织表，即表中数据按照主键顺序存放。而聚集索引(clustered index)就是按照每张表的主键构造一棵B+树，同时叶子节点中存放的即为整张表的行记录数据，也将聚集索引的叶子节点称为数据页。个数据页都通过一个双向链表来进行链接。

## 辅助索引

对于辅助索引(Secondary Index，也称非聚集索引)，叶子节点并不包含行记录的
全部数据。叶子节点除了包含键值以外，每个叶子节点中的索引行中还包含了一个书签
( bookmark)。 该书签用来告诉InnoDB存储引擎哪里可以找到与索引相对应的行数据。由
于InnoDB存储引擎表是索引组织表，因此InnoDB存储引擎的辅助索引的书签就是相应
行数据的聚集索引键。


## Online DDL

此外，不仅是辅助索引，以下这几类DDL操作都可以通过“在线”的方式进行操作:
- 辅助索引的创建与删除
- 改变自增长值
- 添加或删除外键约束
- 列的重命名

InnoDB存储引擎实现OnlineDDL的原理是在执行创建或者删除操作的同时，将INSERT、UPDATE、DELETE这类DML操作日志写人到一个缓存中。待完成索引创
建后再将重做应用到表上，以此达到数据的一致性。这个缓存的大小由参数innodb_online_alter_log_max_size 控制，默认的大小为128MB。
若用户更新的表比较大，并且在创建过程中伴有大量的写事务，如遇到 innodb_online_alter_log_max_size 的空间不能存放日志时，会抛出类似如下的错误:

```log
Error: 1799SQLSTATE : HY000 (ER_INNODB_ONLINE_LOG_TOO_BIG)
Message: Creating index'idx_aaa' required more than 'innodb_online_alter_log_max_size' bytes of modification log. Please try again.
```

## Cardinality

当执行SQL语句ANALYZE TABLE、SHOW TABLE STATUS、SHOW INDEX以及访问INFORMATION_ SCHEMA架构下的表TABLES和STATISTICS时会导致
InnoDB存储引擎去重新计算索引的Cardinality值。若表中的数据量非常大，并且表中存在多个辅助索引时，执行上述这些操作可能会非常慢。虽然用户可能并不希望去更新Cardinality值。

## 覆盖索引

InnoDB存储引擎支持覆盖索引(covering index,或称索引覆盖)，即从辅助索引中
就可以得到查询的记录，而不需要查询聚集索引中的记录。使用覆盖索引的一个好处是
辅助索引不包含整行记录的所有信息，故其大小要远小于聚集索引，因此可以减少大量的IO操作。