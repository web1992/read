# 第6章 锁

- 数据库系统使用锁是为了支持对共享资源进行并发访问,提供数据的完整性和`一致性`。
- 表锁
- 页锁
- 行锁
- 热点数据页
- 乐观并发
- 悲观并发
- lock 与 latch
- latch一般称为闩锁(轻量级的锁)
- lock的对象是事务，用来锁定的是数据库中的对象，如表、页、行。
- SHOW ENGINE INNODB MUTEX
- 共享锁(S Lock)，允许事务读一行数据。
- 排他锁(X Lock)，允许事务删除或更新一行数据.
- 意向锁 ( Intention Lock )
- 意向共享锁
- 意向排他锁
- SHOW ENGINE INNODB STATUS
- INFORMATION_SCHEMA.INNODB_TRX
- INFORMATION_SCHEMA.INNODB_LOCK__WAITS
- INFORMATION_SCHEMA.INNODB_LOCKS
- 一致性非锁定读（快照读，当前读）
- 多版本并发控制(Multi Version Concurrency Control, MVCC)
- 最新一个快照(fresh snapshot)
- 两种一致性的锁定读( locking read)操作:
- SELECT ... FOR UPDATE (X锁)
- SELECT ... LOCK IN SHARE MODE (S锁)
- AUTO-INC Locking
- Phantom Problem
- 脏页

## 共享锁 排他锁

如果一个事务T1已经获得了行r的共享锁，那么另外的事务T2可以立即获得行r
的共享锁，因为读取并没有改变行r的数据，称这种情况为锁兼容(Lock Compatible)。
但若有其他的事务T3想获得行r的排他锁，则其必须等待事务T1、T2释放行r.上的共享锁---这种情况称为锁不兼容。

## 意向共享锁 意向排他锁

- 1)意向共享锁(IS Lock),事务想要获得一张表中某几行的共享锁
- 2)意向排他锁(IX Lock)，事务想要获得一张表中某几行的排他锁

## 一致性非锁定读

一致性的非锁定读(consistent nonlocking read)是指 InnoDB 存储引擎通过行多版本控制(multi versioning) 的方式来读取当前执行时间数据库中行的数据。
如果读取的行正在执行 DELETE 或 UPDATE 操作，这时读取操作不会因此去等待行上锁的释放。相反地，InnoDB 存储引擎会去读取行的一个快照数据。如图6-4所示。

![mysql-innodb-chapter-06-4.drawio.svg](./images/mysql-innodb-chapter-06-4.drawio.svg)

在事务隔离级别READ COMMITTED和REPEATABLE READ (InnoDB 存储引擎的默认事务隔离级别)下，InnoDB存储引擎使用非锁定的一致性读。
然而，对于快照数据的定义却不相同。在READ COMMITTED事务隔离级别下，对于快照数据，非一致性读总是读取被锁定行的最新一份快照数据。
而在REPEATABLE READ事务隔离级别下，对于快照数据，非一致性读总是读取事务开始时的行数据版本。

`SELECT...FOR UPDATE`对读取的行记录加一个X锁，其他事务不能对已锁定的行加上任何锁。
`SELECT...LOCK IN SHARE MODE`对读取的行记录加一个S锁，其他事务可以向被锁定的行加S锁，但是如果加X锁，则会被阻塞。

## 锁分类(3种算法)

- Record Lock: 单个行记录上的锁
- Gap Lock: 间隙锁，锁定一个范围，但不包含记录本身
- Next-Key Lock : Gap Lock + Record Lock, 锁定一个范围，并且锁定记录本身

Next-Key Lock降级为Record Lock仅在查询的列是唯一索引的情况下。

解决 Phantom Problem 问题：

Phantom Problem是指在同一事务下，连续执行两次同样的SQL语句可能导致不同的结果，第二次的SQL语句可能会返回之前不存在的行。

## 锁问题

- 幻读
- 脏度
- 不可重复度
- 阻塞
- 死锁
- 丢失更新的解决办法，select ... for update

不可重复读是指在一个事务内多次读取同一数据集合。在这个事务还没有结束时，另外一个事务也访问该同一数据集合，并做了一些DML操作。因此，在第一个事务中的两次读数据之间，
由于第二个事务的修改，那么第一个事务两次读到的数据可能是不一样的。这样就发生了在一个事务内两次读到的数据是不一样的情况，这种情况称为不可重复读。

在InnoDB存储引擎中，通过使用Next-Key Lock算法来避免不可重复读的问题。在MySQL官方文档中将不可重复读的问题定义为Phantom Problem，即幻像问题。
在Next-Key Lock算法下，对于索引的扫描，不仅是锁住扫描到的索引，而且还锁住这些索引覆盖的范围(gap)。
因此在这个范围内的插人都是不允许的。这样就避免了另外的事务在这个范围内插人数据导致的不可重复读的问题。
因此，InnoDB 存储引擎的默认事务隔离级别是READ REPEATABLE,采用Next-Key Lock算法，避免了不可重复读的现象。

## Phantom Problem 幻读问题

在默认的事务隔离级别下，即REPEATABLE READ下，InnoDB存储引擎采用Next-Key Locking机制来避免Phantom Problem (幻像问题)。

InnoDB存储引擎采用Next-Key Locking的算法避免Phantom Problem。

InnoDB存储引擎采用Next-Key Locking的算法避免Phantom Problem。对于上述的SQL语句`SELECT * FROM t WHERE a>2 FOR UPDATE`，
其锁住的不是5这单个值，而是对(2, +∞)这个范围加了X锁。因此任何对于这个范围的插人都是不被允许的，从而避免Phantom Problem。

InnoDB存储引擎默认的事务隔离级别是REPEATABLE READ,在该隔离级别下，其采用Next-KeyLocking的方式来加锁。
而在事务隔离级别READ COMMITTED下，其仅采用RecordLock，因此在上述的示例中，会话A需要将事务的隔离级别设置为READ COMMITTED。

- REPEATABLE READ - Next-KeyLocking
- READ COMMITTED - RecordLock

## 不可重复度

不可重复读是指在一个事务内多次读取同一数据集合。在这个事务还没有结束时，另外一个事务也访问该同一数据集合，
并做了一些DML操作。因此，在第一个事务中的两次读数据之间，由于第二个事务的修改，那么第一个事务两次读到的数据可能是不
一样的。这样就发生了在一个事务内两次读到的数据是不一样的情况，这种情况称为不可重复读。

不可重复读和脏读的区别是:脏读是读到未提交的数据，而不可重复读读到的却是已经提交的数据，但是其违反了数据库事务一致性的要求。可以通过下面一个例子来观察不可重复读的情况，如表6-16所示。


在InnoDB存储引擎中，通过使用Next-Key Lock算法来避免不可重复读的问题。在MySQL官方文档中将不可重复读的问题定义为Phantom Problem,即幻像问题。
在Next-Key Lock算法下，对于索引的扫描，不仅是锁住扫描到的索引，而且还锁住这些索引覆盖的范围(gap)。 
因此在这个范围内的插入都是不允许的。这样就避免了另外的事务在这个范围内插人数据导致的不可重复读的问题。
因此，InnoDB 存储引擎的默认事务隔离级别是READ REPEATABLE,采用Next-Key Lock算法，避免了不可重复读的现象。

## 丢失更新


## 死锁

- wait for graph 等待图
