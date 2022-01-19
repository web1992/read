# redo & undo

- insert undo log
- update undo log
- purge 操作
- MVCC 事物引用 undo log
- Binary Log Group Commit (BLGC).

## redo log

- redo log 重做日志 用来保证事务的原子性和持久性
- redo log 恢复的是提交事务修改的页操作
- redo log 是物理日志，记录的是页的物理修改操作

## undo log

用来保证事务的一致性

- undo log 回滚行记录到指定的版本
- undo log 是逻辑日志 根据每行进行记录
- insert undo log 是指在insert 操作中产生的undo log
- update undo log 记录的是对delete和update操作产生的undolog

## Buffer poll

内存Buffer

## 两阶段提交

然而在InnoDB1.2版本之前，在开启二进制日志后，InnoDB存储引擎的group
commit功能会失效，从而导致性能的下降。并且在线环境多使用replication环境，因此
二进制日志的选项基本都为开启状态，因此这个问题尤为显著。

导致这个问题的原因是在开启二进制日志后，为了保证存储引擎层中的事务和二进
制日志的一致性，二者之间使用了两阶段事务，其步骤如下:
- 1)当事务提交时InnoDB存储引擎进行prepare 操作。
- 2) MySQL数据库上层写人二进制日志。
- 3) InnoDB存储引擎层将日志写人重做日志文件。
    - a)修改内存中事务对应的信息，并且将日志写人重做日志缓冲。
    - b)调用fsync将确保日志都从重做日志缓冲写入磁盘。

一旦步骤2中的操作完成，就确保了事务的提交，即使在执行步骤3时数据库
发生了宕机。**此外需要注意的是，每个步骤都需要进行一次fsync操作才能保证上下两层数据的一致性**。
步骤2的fsync由参数sync_binlog控制，步骤3的fsync由参数innodb_fush_log_at_trx_commit 控制。因此上述整个过程如图7-18所示。

## Links

- [必须了解的mysql三大日志-binlog、redo log和undo log](https://segmentfault.com/a/1190000023827696)
- [https://dev.mysql.com/doc/refman/5.7/en/innodb-redo-log.html](https://dev.mysql.com/doc/refman/5.7/en/innodb-redo-log.html)
- [https://dev.mysql.com/doc/refman/5.7/en/innodb-undo-logs.html](https://dev.mysql.com/doc/refman/5.7/en/innodb-undo-logs.html)
