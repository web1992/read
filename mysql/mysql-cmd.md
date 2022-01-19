# mysql 常用的命令

## table

```sql
# 查询表的状态
show table status like 'user';
show table status;

show processlist;

show variables like 'transaction_isolation';
```


select * from information_schema.innodb_trx where TIME_TO_SEC(timediff(now(),trx_started))>60