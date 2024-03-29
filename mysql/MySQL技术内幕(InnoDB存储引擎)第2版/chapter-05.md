# 第5章 索引与算法

- 事前做好添加索引的准备
- 索引太多也不好，索引的更新有需要CPU时间
- B+树索引
- 二分查找(折半查找) binary serach
- 在介绍B+树前，需要先了解一下二叉查找树。B+树是通过二叉查找树，再由平衡二叉树，B树演化而来。相信在任何一本有关数据结构的书中
- 全文索引
- 哈希索引
- AVL树（平衡二叉树）
- B+树的插入
- B+树的高度较小，可以减少IO次数，提高性能
- 最优二叉树
- 聚集索引(clustered inex)和辅助索引(secondary inex)
- Fast Index Creation
- Online DDL
- innodb_online_alter_log_max_size
- Cardinality 值的采样更新
- 覆盖索引
- FORCE INDEX
- Multi-Range Read 优化(MRR) 减少随机IO Using MRR
- 书签访问
- Index Condition Pushdown (ICP) 优化

## B+树

B+树是为磁盘或其他直接存取辅助设备设计的一种平衡查找树。在B+树中，所有记录节点都是按键值的大小顺序存放在同一层的叶子节点上，由各叶子节点指针进行连接.

B+树中的B不是代表二叉(binary),而是代表平衡(balance),因为B+树是从最早的平衡二叉树演化而来，但是B+树不是一个二叉树。

另一个常常被DBA忽视的问题是:B+树索引并不能找到一个给定键值的具体行。B+树索引能找到的只是被查找`数据行所在的页`。然后数据库通过把页读入到内存，再在内存中进行查找，最后得到要查找的数据。

我来精简地对B+树做个介绍:B+树是为磁盘或其他直接存取辅助设备设计的一种平衡查找树。在B+树中，所有记录节点都是按键值的大
小顺序存放在同一层的叶子节点上，由各叶子节点指针进行连接。先来看一个B+树，其高度为2，每页可存放4条记录，扇出(fanout)为5，如图5-6所示。

![mysql-innodb-chapter-05-06.drawio.svg](./images/mysql-innodb-chapter-05-06.drawio.svg)


## 平衡二叉树

平衡二叉树的查询速度的确很快，但是维护一棵平衡二叉树的代价是非常大的。通常来说，需要1次或多次左旋和右旋来得到插入或更新后树的平衡性。

## 聚集索引

InnoDB存储引擎表是索引组织表，即表中数据按照主键顺序存放。而聚集索引(clustered index)就是按照每张表的主键构造一棵B+树，同时叶子节点中存放的即为整张表的行记录数据，也将聚集索引的叶子节点称为数据页。每个数据页都通过一个双向链表来进行链接。

## 辅助索引

对于辅助索引(Secondary Index，也称非聚集索引)，叶子节点并不包含行记录的全部数据。叶子节点除了包含键值以外，每个叶子节点中的索引行中还包含了一个书签(bookmark)。 该书签用来告诉InnoDB存储引擎哪里可以找到与索引相对应的行数据。由于InnoDB存储引擎表是索引组织表，因此InnoDB存储引擎的辅助索引的书签就是相应行数据的聚集索引键。


## Online DDL

此外，不仅是辅助索引，以下这几类DDL操作都可以通过“在线”的方式进行操作:
- 辅助索引的创建与删除
- 改变自增长值
- 添加或删除外键约束
- 列的重命名

InnoDB存储引擎实现OnlineDDL的原理是在执行创建或者删除操作的同时，将INSERT、UPDATE、DELETE这类DML操作日志写入到一个缓存中。待完成索引创
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

## 不使用索引的情况

- 通过书签访问查询整行的数据，此时的IO操作是无序的，速度可能变慢
- 顺序读的速度要远远大于离散读

## Multi-Range Read 

- MRR使数据访问变得较为顺序。在查询辅助索引时，首先根据得到的查询结果,按照主键进行排序，并按照主键排序的顺序进行书签查找。
- 减少缓冲池中页被替换的次数。
- 批量处理对键值的查询操作。

对于InnoDB和MyISAM存储引擎的范围查询和JOIN查询操作，MRR的工作方式
- 将查询得到的辅助索引键值存放于一个缓存中，这时缓存中的数据是根据辅助索引键值排序的。
- 将缓存中的键值根据RowID进行排序。
- 根据RowID的排序顺序来访问实际的数据文件。

## Index Condition Pushdown

和Multi-Range Read -样，Index Condition Pushdown同样是MySQL 5.6开始支持的一种根据索引进行查询的优化方式。之前的MySQL数据库版本不支持Index Condition Pushdown，当进行索引查询时，首先根据索引来查找记录，然后再根据WHERE条件来过滤记录。在支持Index Condition Pushdown后，MySQL数据库会在取出索引的同时，判断是否可以进行WHERE条件的过滤，也就是将WHERE的部分过滤操作放在了存储引擎层。在某些查询下，可以大大减少上层SQL层对记录的索取(fetch), 从而提高数据库的整体性能。

## Links 

- [B+ 红黑树对比](https://www.cnblogs.com/yufeng218/p/12465694.html)
