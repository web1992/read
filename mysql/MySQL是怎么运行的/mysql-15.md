# 第15章 查询优化的百科全书-Explain详解（上）

- Explain 执行计划
- union 会去重
- union all 不会去重
- select_type
- possible_keys和key


## select_type

|名称 |描述|
|----|----|
SIMPLE               | Simple SELECT (not using UNION or subqueries)
PRIMARY              | Outermost SELECT
UNION                | Second or later SELECT statement in a UNION
UNION RESULT         | Result of a UNION
SUBQUERY             | First SELECT in subquery
DEPENDENT SUBQUERY   | First SELECT in subquery, dependent on outer query
DEPENDENT UNION      | Second or later SELECT statement in a UNION, dependent on outer query
DERIVED              | Derived table
MATERIALIZED         | Materialized subquery
UNCACHEABLE SUBQUERY | A subquery for which the result cannot be cached and must be re-evaluated for each row of the outer query
UNCACHEABLE UNION    | The second or later select in a UNION that belongs to an uncacheable subquery (see UNCACHEABLESUBQUERY)

- SIMPLE  
查询语句中不包含 UNION 或者子查询的查询都算作是 SIMPLE 类型（连接join查询也算是 SIMPLE 类型）

- PRIMARY
对于包含 UNION 、 UNION ALL 或者子查询的大查询来说，它是由几个小查询组成的，其中最左边的那个查询的 select_type 值就是 PRIMARY。

- UNION
对于包含 UNION 或者 UNION ALL 的大查询来说，它是由几个小查询组成的，其中除了最左边的那个小查询以外，其余的小查询的 select_type 值就是 UNION ，可以对比上一个例子的效果，这就不多举例子了。

- UNION RESULT
MySQL 选择使用临时表来完成 UNION 查询的去重工作，针对该临时表的查询的 select_type 就是 UNION RESULT ，例子上边有，就不赘述了。

- SUBQUERY
如果包含子查询的查询语句不能够转为对应的 semi-join 的形式，并且该子查询是不相关子查询，并且查询优化器决定采用将该子查询物化的方案来执行该子查询时，该子查询的第一个 SELECT 关键字代表的那个查询的 select_type 就是 SUBQUERY ，


## 访问方式

完整的访问方法如下： 
system ， const ，eq_ref ， ref ， fulltext ， ref_or_null ， index_merge ， unique_subquery ， index_subquery ，range ， index ， ALL


- system
当表中只有一条记录并且该表使用的存储引擎的统计数据是精确的，比如MyISAM、Memory，那么对该表的
访问方法就是 system 。

- const
这个我们前边唠叨过，就是当我们根据主键或者唯一二级索引列与常数进行等值匹配时，对单表的访问方法
就是 const 

- eq_ref
在连接查询时，如果被驱动表是通过主键或者唯一二级索引列等值匹配的方式进行访问的（如果该主键或者
唯一二级索引是联合索引的话，所有的索引列都必须进行等值比较），则对该被驱动表的访问方法就是eq_ref

- ref
当通过普通的二级索引列与常量进行等值匹配时来查询某个表，那么对该表的访问方法就可能是 ref

- fulltext
全文索引，我们没有细讲过，跳过～

- ref_or_null
当对普通二级索引进行等值匹配查询，该索引列的值也可以是 NULL 值时，那么对该表的访问方法就可能是 ref_or_null

- index_merge
一般情况下对于某个表的查询只能使用到一个索引，但我们唠叨单表访问方法时特意强调了在某些场景下可
以使用 Intersection 、 Union 、 Sort-Union 这三种索引合并的方式来执行查询

- unique_subquery
类似于两表连接中被驱动表的 eq_ref 访问方法， unique_subquery 是针对在一些包含 IN 子查询的查询语
句中，如果查询优化器决定将 IN 子查询转换为 EXISTS 子查询，而且子查询可以使用到主键进行等值匹配的
话，那么该子查询执行计划的 type 列的值就是 unique_subquery ，

- index_subquery
index_subquery 与 unique_subquery 类似，只不过访问子查询中的表时使用的是普通的索引，

- range
如果使用索引获取某些 范围区间 的记录，那么就可能使用到 range 访问方法

- ALL
最熟悉的全表扫描


## possible_keys

possible_keys 列中的值并不是越多越好，可能使用的索引越多，查询优化器计算查询成本时就得花费更长时间，所以如果可以的话，尽量删除那些用不到的索引。

## key_len

key_len 列表示当优化器决定使用某个索引执行查询时，该索引记录的最大长度，它是由这三个部分构成的：
对于使用固定长度类型的索引列来说，它实际占用的存储空间的最大长度就是该固定值，对于指定字符集的
变长类型的索引列来说，比如某个索引列的类型是 VARCHAR(100) ，使用的字符集是 utf8 ，那么该列实际占
用的最大存储空间就是 100 × 3 = 300 个字节。
如果该索引列可以存储 NULL 值，则 key_len 比不可以存储 NULL 值时多1个字节。
对于变长字段来说，都会有2个字节的空间来存储该变长列的实际长度。