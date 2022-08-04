# 第12章 谁最便宜就选谁-MySQL基于成本的优化

- I/O 成本
- CPU 成本
- 执行计划
- possible keys
- SHOW TABLE STATUS 语句来查看表的统计信息
- Rows
- Data_length
- 执行计划成本的计算
- eq_range_index_dive_limit
- SHOW INDEX FROM single_table;
- Cardinality
- 扇出 fanout （驱动表的大小）
- condition filtering
- 尽量减少驱动表的扇出
- 对被驱动表的访问成本尽量低
- 尽量在被驱动表的连接列上建立索引
- 系统变量 optimizer_search_depth
- optimizer_prune_level 启发式规则
- SHOW TABLES FROM mysql LIKE '%cost%';
- server_cost
- engine_cost
- 临时表
- 磁盘临时表
- 内存临时表
- FLUSH OPTIMIZER_COSTS; 让系统重新加载这个表的值

## 执行计划

1. 根据搜索条件，找出所有可能使用的索引
2. 计算全表扫描的代价
3. 计算使用不同索引执行查询的代价
4. 对比各种执行方案的代价，找出成本最低的那一个

## 被驱动表的成本

这一点对于我们实际书写连接查询语句时十分有用，我们需要尽量在被驱动表的连接列上建立索引，这样就
可以使用 ref 访问方法来降低访问被驱动表的成本了。如果可以，被驱动表的连接列最好是该表的主键或者
唯一二级索引列，这样就可以把访问被驱动表的成本降到更低了。