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
- [🔥mysql-index.md](mysql-index.md)
- [🔥mysql-page.md](mysql-page.md)
- [🔥mysql-redo-undo.md](mysql-redo-undo.md)
- [🔥mysql-innodb.md](mysql-innodb.md)

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

使用缓存的查询

```sql
+--------------------------------+----------+
| Status                         | Duration |
+--------------------------------+----------+
| starting                       | 0.000144 |
| Waiting for query cache lock   | 0.000022 |
| starting                       | 0.000014 |
| checking query cache for query | 0.000058 |
| checking permissions           | 0.000021 |
| Opening tables                 | 0.000031 |
| init                           | 0.000033 |
| System lock                    | 0.000021 |
| Waiting for query cache lock   | 0.000009 |
| System lock                    | 0.000041 |
| optimizing                     | 0.000060 |
| statistics                     | 0.000043 |
| preparing                      | 0.000030 |
| executing                      | 0.000019 |
| Sending data                   | 0.000087 |
| end                            | 0.000011 |
| query end                      | 0.000032 |
| closing tables                 | 0.000012 |
| freeing items                  | 0.000022 |
| Waiting for query cache lock   | 0.000011 |
| freeing items                  | 0.000030 |
| Waiting for query cache lock   | 0.000015 |
| freeing items                  | 0.000015 |
| storing result in query cache  | 0.000016 |
| cleaning up                    | 0.000035 |
+--------------------------------+----------+
```

为使用查询的缓存

```sql
+----------------------+----------+
| Status               | Duration |
+----------------------+----------+
| starting             | 0.000075 |
| checking permissions | 0.000025 |
| Opening tables       | 0.000032 |
| init                 | 0.000043 |
| System lock          | 0.000031 |
| optimizing           | 0.000020 |
| statistics           | 0.000030 |
| preparing            | 0.000025 |
| executing            | 0.000015 |
| Sending data         | 0.000133 |
| end                  | 0.000028 |
| query end            | 0.000027 |
| closing tables       | 0.000028 |
| freeing items        | 0.000037 |
| cleaning up          | 0.000058 |
+----------------------+----------+
```
