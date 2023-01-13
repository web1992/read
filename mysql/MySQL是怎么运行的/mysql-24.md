# 第24章 一条记录的多幅面孔-事务的隔离级别与 MVCC

- 事务隔离级别
- 脏写（ Dirty Write ）如果一个事务修改了另一个未提交事务修改过的数据
- 脏读（ Dirty Read ）
- 不可重复读（Non-Repeatable Read）
- 幻读（Phantom）
- 隔离级别
- READ UNCOMMITTED ：未提交读
- READ COMMITTED ：已提交读
- REPEATABLE READ ：可重复读
- SERIALIZABLE ：可串行化
- SET [GLOBAL|SESSION] TRANSACTION ISOLATION LEVEL level
- MVCC
- 版本链
- row_id
- trx_id
- roll_pointer
- Undo Log Segment
- ReadView
- READ COMMITTED 和 REPEATABLE READ 隔离级别的的一个非常大的区别就是它们生成ReadView的时机不同
- READ COMMITTED —— 每次读取数据前都生成一个ReadView
- REPEATABLE READ —— 在第一次读取数据时生成一个ReadView
- insert undo
- update undo
- delete mark
- purge线程


## 不可重复读（Non-Repeatable Read）

如果一个事务只能读到另一个已经提交的事务修改过的数据，并且其他事务每对该数据进行一次修改并提交
后，该事务都能查询得到最新值，那就意味着发生了`不可重复读`


## 幻读（Phantom）

幻读（Phantom）
如果一个事务先根据某些条件查询出一些记录，之后另一个事务又向表中插入了符合这些条件的记录，原先
的事务再次按照该条件查询时，能把另一个事务插入的记录也读出来，那就意味着发生了`幻读` 

## 隔离级别  SQL标准

- READ UNCOMMITTED ：未提交读。
- READ COMMITTED ：已提交读。
- REPEATABLE READ ：可重复读。
- SERIALIZABLE ：可串行化。


SQL标准 中规定，针对不同的隔离级别，并发事务可以发生不同严重程度的问题，具体情况如下：

|隔离级别| 脏读| 不可重复读| 幻读|
|--------|-----|-----------|-----|
|READ UNCOMMITTED | Possible     |Possible     |Possible
|READ COMMITTED   | Not Possible |Possible     |Possible
|REPEATABLE READ  | Not Possible |Not Possible |Possible
|SERIALIZABLE     | Not Possible |Not Possible |Not Possible

也就是说：
- READ UNCOMMITTED 隔离级别下，可能发生 脏读 、 不可重复读 和 幻读 问题。
- READ COMMITTED 隔离级别下，可能发生 不可重复读 和 幻读 问题，但是不可以发生 脏读 问题。
- REPEATABLE READ 隔离级别下，可能发生 幻读 问题，但是不可以发生 脏读 和 不可重复读 的问题。
- SERIALIZABLE 隔离级别下，各种问题都不可以发生。

## SQL标准

不同的数据库厂商对 SQL标准 中规定的四种隔离级别支持不一样，比方说 Oracle 就只支持 READ COMMITTED 和
SERIALIZABLE 隔离级别。本书中所讨论的 MySQL 虽然支持4种隔离级别，但与 SQL标准 中所规定的各级隔离级
别允许发生的问题却有些出入，MySQL在REPEATABLE READ隔离级别下，是可以禁止幻读问题的发生的（关
于如何禁止我们之后会详细说明的）。
MySQL 的默认隔离级别为 REPEATABLE READ ，我们可以手动修改一下事务的隔离级别。

```sql
SET GLOBAL TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SHOW VARIABLES LIKE 'transaction_isolation';

SELECT @@transaction_isolation;
```


## ReadView

对于使用 READ UNCOMMITTED 隔离级别的事务来说，由于可以读到未提交事务修改过的记录，所以直接读取记录
的最新版本就好了；对于使用 SERIALIZABLE 隔离级别的事务来说，设计 InnoDB 的大叔规定使用加锁的方式来访
问记录（加锁是啥我们后续文章中说哈）；对于使用 READ COMMITTED 和 REPEATABLE READ 隔离级别的事务来
说，都必须保证读到已经提交了的事务修改过的记录，也就是说假如另一个事务已经修改了记录但是尚未提交，
是不能直接读取最新版本的记录的，核心问题就是：`需要判断一下版本链中的哪个版本是当前事务可见的`。

- m_ids          表示在生成 ReadView 时当前系统中活跃的读写事务的 事务id 列表
- min_trx_id     表示在生成 ReadView 时当前系统中活跃的读写事务中最小的 事务id ，也就是 m_ids 中的最小值
- max_trx_id     表示生成 ReadView 时系统中应该分配给下一个事务的 id 值
- creator_trx_id 表示生成该 ReadView 的事务的 事务id 


## MVCC

从上边的描述中我们可以看出来，所谓的 MVCC （Multi-Version Concurrency Control ，多版本并发控制）指的就
是在使用 READ COMMITTD 、 REPEATABLE READ 这两种隔离级别的事务在执行普通的 SEELCT 操作时访问记录的版
本链的过程，这样子可以使不同事务的 读-写 、 写-读 操作并发执行，从而提升系统性能。 READ COMMITTD 、
REPEATABLE READ 这两个隔离级别的一个很大不同就是：生成ReadView的时机不同，READ COMMITTD在每一
次进行普通SELECT操作前都会生成一个ReadView，而REPEATABLE READ只在第一次进行普通SELECT操作
前生成一个ReadView，之后的查询操作都重复使用这个ReadView就好了。
