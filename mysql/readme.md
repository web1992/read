# mysql

- [group-by.md](group-by.md)
- [high-performance-MySQL-blog.md](high-performance-MySQL-blog.md)
- [high-performance-MySQL.md](high-performance-MySQL.md)
- [join.md](join.md)
- [limit.md](limit.md)
- [mysql-when-create-temporary-table.md](mysql-when-create-temporary-table.md)
- [table.md](table.md)
- [tokudb.md](tokudb.md)
- [mysql-transaction.md](mysql-transaction.md)

## 查询优化

- 使用 force index 优化 possible_keys 选择的问题(所有太多 possible_keys 过程消耗时间也多)

## 优化案例

- [https://tech.meituan.com/2014/06/30/mysql-index.html](https://tech.meituan.com/2014/06/30/mysql-index.html)

## optimizer_trace

```sql
set session optimizer_trace='enabled=on';
select * from t_user;
select * from information_schema.optimizer_trace\G;

set session optimizer_trace='enabled=off';
```

## profile

```sql
set profiling=1;
select * from t_user;
show profiles;
show profile for query 1;
```
