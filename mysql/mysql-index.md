# mysql index

## index

InnoDB tables always have a clustered index representing the primary key

## covering index

An index that includes all the columns retrieved by a query. Instead of using the index values as pointers to find the full table rows, the query returns values from the index structure, saving disk I/O. InnoDB can apply this optimization technique to more indexes than MyISAM can, because InnoDB secondary indexes also include the primary key columns. InnoDB cannot apply this technique for queries against tables modified by a transaction, until that transaction ends.

Any column index or composite index could act as a covering index, given the right query. Design your indexes and queries to take advantage of this optimization technique wherever possible.

根据索引列个数和功能描述不同索引也可以分为：联合索引和覆盖索引。

- 联合索引是指在多个字段联合组建索引的。
- 当通过索引即可查询到所有记录，不需要回表到聚簇索引时，这类索引也叫作覆盖索引。
- 主键查询是天然的覆盖索引，联合索引可以是覆盖索引。

## clustered index

The InnoDB term for a `primary` `key` index. `InnoDB` table storage is organized based on the values of the primary key columns, to speed up queries and sorts involving the primary key columns. For best performance, choose the primary key columns carefully based on the most performance-critical queries. Because modifying the columns of the clustered index is an expensive operation, choose primary columns that are rarely or `never updated`.

In the Oracle Database product, this type of table is known as an index-organized table.

MySQL 聚簇索引和辅助索引

聚簇索引是一种数据存储方式，它表示表中的数据按照主键顺序存储，是索引组织表。InnoDB 的聚簇索引就是按照主键顺序构建 B+Tree，
B+Tree 的叶子节点就是行记录，数据行和主键值紧凑地存储在一起。这也意味着 InnoDB 的主键索引就是数据表本身，它按主键顺序存放了整张表的数据。

而 InnoDB 辅助索引（也叫作二级索引）只是根据索引列构建 B+Tree，但在 B+Tree 的每一行都存了主键信息，加速回表操作

## 最左前缀匹配原则

通过 key_len 计算也帮助我们了解索引的最左前缀匹配原则。

最左前缀匹配原则是指在使用 B+Tree 联合索引进行数据检索时，MySQL 优化器会读取谓词（过滤条件）并按照联合索引字段创建顺序一直向右匹配直到遇到范围查询或非等值查询后停止匹配，此字段之后的索引列不会被使用，这时计算 key_len 可以分析出联合索引实际使用了哪些索引列。

## Links

- [https://dev.mysql.com/doc/refman/5.7/en/glossary.html#glos_index](https://dev.mysql.com/doc/refman/5.7/en/glossary.html#glos_index)
