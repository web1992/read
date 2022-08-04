# 第13章 兵马未动，粮草先行-InnoDB统计数据是如何收集的

- 以表为单位来收集和存储统计数据的
- innodb_stats_persistent
- STATS_PERSISTENT 表的统计数据的存储方式 1=磁盘，0=内存
- SHOW TABLES FROM mysql LIKE 'innodb%';
- innodb_stats_persistent_sample_pages
- STATS_SAMPLE_PAGES
