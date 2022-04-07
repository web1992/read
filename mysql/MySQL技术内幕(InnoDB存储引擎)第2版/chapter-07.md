# 第7章 事物

- ACID
- 原子性(atomicity)
- 一致性(consistency)
- 隔离性(isolation)
- 持久性(durability)
- 扁平事务(Flat Transactions)
- 带有保存点的扁平事务( Flat Transactions with Savepoints )
- 链事务(Chained Transactions )
- 嵌套事务(Nested Transactions )
- 分布式事务(Distributed Transactions )
- 重做日志缓冲(redo log buffer)
- 重做日志文件(redo log file)
- fsync 操作
- log block
- redo log
- undo log 
- log group
- LSN Log Sequence Number (日志序列号)
- insert undo log
- update undo log
- purge 操作
- MVCC 事物引用 undo log
- 两阶段提交： 二进制日志+undo log 
- Binary Log Group Commit (BLGC)
- 事物中出现异常，事物并不会自动回滚，需要明确的执行 ROLLBACK 动作进行回滚
- 隐式提交的SQL语句
- 事物隔离级别
- LOCK IN SHARE MODE，每个读取操作加一个共享锁。
- STATEMENT 基于SQL 的日志（不建议使用）
- ROW格式的二进制 （建议使用） 
- XA 事物
- 长事物

## redo-log

重做日志用来实现事务的持久性，即事务ACID中的D。其由两部分组成:一是内存中的重做日志缓冲(redo log buffer)，其是易失的;二是重做日志文件(redo log file),其是持久的。

InnoDB是事务的存储引擎，其通过Force Log at Commit机制实现事务的持久性，即当事务提交(COMMIT)时，必须先将该事务的所有日志写人到重做日志文件进行持久化，待事务的COMMIT操作完成才算完成。这里的日志是指重做日志，在InnoDB存储引擎中，由两部分组成，即redo log和undo log。redo log 用来保证事务的持久性，undolog用来帮助`事务回滚`及`MVCC`的功能。redo log基本上都是顺序写的，在数据库运行时不需要对redo log的文件进行读取操作。而undo log是需要进行随机读写的。

为了确保每次日志都写人重做日志文件，在每次将重做日志缓冲写人重做日志文件后，InnoDB存储引擎都需要调用一次fsync操作。由于重做日志文件打开并没有使用`O_DIRECT`选项，因此重做日志缓冲先写入文件系统缓存。为了确保重做日志写入磁盘，必须进行一次fsync操作。由于fsync的效率取决于磁盘的性能，因此磁盘的性能决定了事务提交的性能，也就是数据库的性能。

参数`innodb_flush_log_at_trx_commit`用来控制重做日志刷新到磁盘的策略。该参数的默认值为1,表示事务提交时必须调用一次fsync操作。还可以设置该参数的值为0和2。0 表示事务提交时不进行写人重做日志操作，这个操作仅在master thread中完成，而在master thread中每1秒会进行一次重做日志文件的fsync操作。2表示事务提交时将重做日志写人重做日志文件，但仅写人文件系统的缓存中，不进行fsync 操作。`在这个设置下，当MySQL数据库发生宕机而操作系统不发生宕机时，并不会导致事务的丢失`。而当操作系统宕机时，重启数据库后会丢失未从文件系统缓存刷新到重做日志文件那部分事务。

## undo-log

1.基本概念
重做日志记录了事务的行为，可以很好地通过其对页进行“重做”操作。但是事务有时还需要进行回滚操作，这时就需要undo。因此在对数据库进行修改时，InnoDB存储引擎不但会产生redo,还会产生一定量的undo。这样如果用户执行的事务或语句由于某种原因失败了，又或者用户用一条ROLLBACK语句请求回滚，就可以利用这些undo信息将数据回滚到修改之前的样子。
redo存放在重做日志文件中，与redo不同，undo存放在数据库内部的一个特殊段(segment)中，这个段称为undo段(undo segment)。undo 段位于共享表空间内。可以通过py_innodb_page_info.py 工具来查看当前共享表空间中undo的数量。

用户通常对undo有这样的误解:undo用于将数据库`物理地恢复`到执行语句或事务之前的样子一但事实并非如此。undo是逻辑日志，因此只是将数据库逻辑地恢复到原来的样子。所有修改都被逻辑地取消了,但是`数据结构`和`页本身`在回滚之后可能大不相同。这是因为在多用户并发系统中，可能会有数十、数百甚至数千个并发事务。数据库的主要任务就是协调对数据记录的并发访问。比如，一行修改。因此，不能将一个页回滚到事务开始的样子，因为这样会影响其他事务正在进行的工作。

例如，用户执行了一个INSERT 10W条记录的事务，这个事务会导致分配一个新的段，即表空间会增大。在用户执行ROLLBACK时，会将插人的事务进行回滚，但是表空间的大小并不会因此而收缩。因此，当InnoDB存储引擎回滚时，`它实际上做的是与先前相反的工作`。对于每个INSERT，InnoDB 存储引擎会完成一个DELETE;对于每个DELETE，InnoDB 存储引擎会执行一个INSERT;对于每个UPDATE，InnoDB 存储引擎会执行一个相反的UPDATE,将修改前的行放回去。除了回滚操作，undo的另一个作用是MVCC，即在InnoDB存储引擎中MVCC的实现是通过undo来完成。当用户读取一行记录时，若该记录已经被其他事务占用，当前事务可以通过undo读取之前的行版本信息，以此实现`非锁定读取`。最后也是最为重要的一点是，undo log会产生redo log,也就是undo log的产生会伴随着redo log的产生，这是因为undo log也需要持久性的保护。

## purge

delete和update操作可能并不直接删除原有的数据。例如，对上一小节所产生的表t执行如下的SQL语句:
```
DELETE FROM t WHERE a=1;
```

表t上列a有聚集索引，列b上有辅助索引。对于上述的delete操作，通过前面关于undo log的介绍已经知道仅是将主键列等于1的记录delete fag设置为1，记录并没有被删除，即记录还是存在于B+树中。其次，对辅助索引上a等于1, b等于1的记录同样没有做任何处理，甚至没有产生undo log。而真正删除这行记录的操作其实被“延时”了，最终在purge操作中完成。

purge用于最终完成delete和update操作。这样设计是因为InnoDB存储引擎支持MVCC，所以记录不能在事务提交时立即进行处理。这时其他事物可能正在引用这行，故InnoDB存储引擎需要保存记录之前的版本。而是否可以删除该条记录通过purge来进行判断。若该行记录已不被任何其他事务引用，那么就可以进行真正的delete操作。可见，purge操作是清理之前的delete和update操作，将上述操作“最终”完成。而实际执行的操作为delete操作，清理之前行记录的版本。

## Group Commit

对于InnoDB存储引擎来说，事务提交时会进行两个阶段的操作:
- 1)修改内存中事务对应的信息，并且将日志写人重做日志缓冲。
- 2)调用fsync将确保日志都从重做日志缓冲写人磁盘。

步骤2)相对步骤1)是一个较慢的过程，这是因为存储引擎需要与磁盘打交道。但当有事务进行这个过程时，其他事务可以进行步骤1)的操作，正在提交的事物完成提交操作后，再次进行步骤2)时，可以将多个事务的重做日志通过- -次fsync刷新到磁盘，这样就大大地减少了磁盘的压力，从而提高了数据库的整体性能。对于写人或更新较为频繁的操作，group commit的效果尤为明显。

然而在InnoDB1.2版本之前，在开启二进制日志后，InnoDB存储引擎的groupcommit功能会失效，从而导致性能的下降。并且在线环境多使用replication环境，因此二进制日志的选项基本都为开启状态，因此这个问题尤为显著。导致这个问题的原因是在开启二进制日志后，为了保证存储引擎层中的事务和二进制日志的一致性，二者之间使用了两阶段事务，其步骤如下:
- 1) 当事务提交时InnoDB存储引擎进行prepare操作。
- 2) MySQL数据库上层写人二进制日志。
- 3) InnoDB存储引擎层将日志写人重做日志文件。
    - a)修改内存中事务对应的信息，并且将日志写人重做日志缓冲。
    - b)调用fsync将确保日志都从重做日志缓冲写人磁盘。

## BLGC Binary Log Group Commit

![图7-21 MySQL 5.6 BLGC的实现方式](./images/mysql-innodb-chapter-07-21.drawio.svg)

在MySQL数据库上层进行提交时首先按顺序将其放人一个队列中，队列中的第一
个事务称为leader,其他事务称为follower, leader 控制着follower 的行为。BLGC的步

骤分为以下三个阶段:
- Flush阶段，将每个事务的二进制日志写人内存中。
- Sync阶段，将内存中的二进制日志刷新到磁盘，若队列中有多个事务，那么仅一次fsync操作就完成了二进制日志的写人，这就是BLGC。
- Commit阶段，leader 根据顺序调用存储引擎层事务的提交，InnoDB存储引擎本就支持group commit， 因此修复了原先由于锁prepare_commit_mutex 导致 group commit失效的问题。

当有一组事务在进行Commit阶段时，其他新事物可以进行Flush阶段，从而使group commit不断生效。当然group commit的效果由队列中事务的数量决定，若每次队列中仅有一个事务，那么可能效果和之前差不多，甚至会更差。但当提交的事务越多时，group commit的效果越明显，数据库性能的提升也就越大。

> 🐶备注🐶
> 本质解决的问题： 二进制日志与InnoDB存储引擎重置日志的顺序问题。


## 隐式提交的SQL语句

以下这些SQL语句会产生一个隐式的提交操作，即执行完这些语句后，会有一个隐式的COMMIT操作。
DDL语句: ALTER DATABASE...UPGRADE DATA DIRECTORY NAME,
ALTER EVENT, ALTER PROCEDURE, ALTER TABLE, ALTER VIEW,
CREATE DATABASE, CREATE EVENT, CREATE INDEX, CREATE
PROCEDURE, CREATE TABLE, CREATE TRIGGER, CREATE VIEW ,
DROP DATABASE, DROP EVENT, DROP INDEX, DROP PROCEDURE,
DROP TABLE, DROP TRIGGER, DROP VIEW, RENAME TABLE,
TRUNCATE TABLE.

用来隐式地修改MySQL架构的操作: CREATE USER、DROP USER、GRANT、ENAME USER、 REVOKE SET PASSWORD.

管理语句: ANALYZE TABLE、 CACHE INDEX、 CHECK TABLE、 LOAD INDEX INTO CACHE、 OPTIMIZE TABLE、 REPAIR TABLE.


## 事物隔离级别

InnoDB存储引擎默认支持的隔离级别是REPEATABLE READ，但是与标准SQL不同的是，InnoDB 存储引擎在REPEATABLE READ事务隔离级别下，
使用Next-Key Lock锁的算法，因此避免幻读的产生。这与其他数据库系统(如Microsoft SQL Server数据库)是不同的。
所以说，InnoDB 存储引擎在默认的REPEATABLE READ的事务隔离级别下已经能完全保证事务的隔离性要求，即达到SQL标准的SERIALIZABLE隔离级别。

## XA

最为常见的内部XA事务存在于binlog与InnoDB存储引擎之间。由于复制的需要，因此目前绝大多数的数据库都开启了`binlog`功能。在事务提交时，先写二进制日志，再写InnoDB存储引擎的重做日志。对上述两个操作的要求也是原子的，即二进制日志和重做日志必须同时写人。若二进制日志先写了，而在写人InnoDB存储引擎时发生了宕机，那么slave可能会接收到master传过去的二进制日志并执行，最终导致了主从不一致的情况。

在图7-23中，如果执行完①、②后在步骤③之前MySQL数据库发生了宕机，则会发生主从不一致的情况。为了解决这个问题，MySQL数据库在binlog与InnoDB存储引擎之间采用XA事务。
当事务提交时，InnoDB存储引擎会先做一个PREPARE操作，将事务的xid写入，接着进行二进制日志的写人，如图7-24所示。
如果在InnoDB存储引擎提交前，MySQL数据库宕机了，那么MySQL数据库在重启后会先检查准备的UXID事务是否已经提交，若没有，则在存储引擎层再进行一次提交操作。

图7-23宕机导致 replication主从不一致的情况

![图7-23宕机导致 replication主从不一致的情况](./images/mysql-innodb-chapter-07-23.drawio.svg)

图7-24 MySQL数据库通过内部XA事务保证主从数据一致

![图7-24 MySQL数据库通过内部XA事务保证主从数据一致](./images/mysql-innodb-chapter-07-24.drawio.svg)

> XA 此处主要解决 binlog 与 redo log 的不一致

## 不好的事物习惯

- 在循环中提交
- 使用自动提交
- 使用自动回滚