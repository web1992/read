# 第13章 兵马未动，粮草先行-InnoDB统计数据是如何收集的

- 以表为单位来收集和存储统计数据的
- innodb_stats_persistent
- STATS_PERSISTENT 表的统计数据的存储方式 1=磁盘，0=内存
- SHOW TABLES FROM mysql LIKE 'innodb%';
- innodb_stats_persistent_sample_pages
- STATS_SAMPLE_PAGES
- innodb_stats_auto_recalc
- ANALYZE TABLE single_table;
- 任何和 NULL 值做比较的表达式的值都为 NULL
- innodb_stats_method 决定着在统计某个索引列不重复值的数量时如何对待 NULL 值