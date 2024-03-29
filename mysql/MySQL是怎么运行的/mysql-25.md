#  第25章 工作面试老大难-锁

- 并发事务
- 读读
- 读写
- 写写
- 锁结构
- 幻读
- MVCC ReadView  undo日志
- 在 READ UNCOMMITTED 隔离级别下， 脏读 、 不可重复读 、 幻读 都可能发生。
- 在 READ COMMITTED 隔离级别下， 不可重复读 、 幻读 可能发生， 脏读 不可以发生。
- 在 REPEATABLE READ 隔离级别下， 幻读 可能发生， 脏读 和 不可重复读 不可以发生。
- 在 SERIALIZABLE 隔离级别下，上述问题都不可以发生。 
- 一致性读（Consistent Reads）
- 锁定读（Locking Reads）
- 行级锁
- 表锁
- 元数据锁  Metadata Locks ，简称 MDL
- DDL （ALTER TABLE 、 DROP TABLE）操作会对表加锁
- 表级别的 S锁 、 X锁
- 表级别的 IS锁 、 IX锁
- 表级别的 AUTO-INC锁
- innodb_autoinc_lock_mode
- 行锁 ，也称为 记录锁 ，顾名思义就是在记录上加的锁
- Record Locks （S锁，X锁）
- Gap Locks
- Next-Key Locks
- Insert Intention Locks 插入意向锁
- 隐式锁

## 并发事务


## 锁结构

- trx信息 ：代表这个锁结构是哪个事务生成的。
- is_waiting ：代表当前事务是否在等待。

![MySQL-事务-01.drawio.svg](./images/MySQL-事务-01.drawio.svg)

获取锁成功、失败

![MySQL-事务-02.drawio.svg](./images/MySQL-事务-02.drawio.svg)

## 幻读问题

幻读问题的产生是因为某个事务读了一个范围的记录，之后别的事务在该范围内插入了新记录，该事务再次读取该范围的记录时，可以读到新插入的记录，所以幻读问题准确的说并不是因为读取和写入一条相同记录而产生的，这一点要注意一下。

过普通的SELECT语句在READ COMMITTED和REPEATABLE READ隔离级别下会使用到MVCC读取记录。
在READ COMMITTED隔离级别下，一个事务在执行过程中每次执行SELECT操作时都会生成一个ReadView，ReadView的存在本身就保证了事务不可以读取到未提交的事务所做的更改，也就是避免了脏读现象；REPEATABLE READ隔离级别下，一个事务在执行过程中只有第一次执行SELECT操作才会生成一个ReadView，之后的SELECT操作都复用这个ReadView，这样也就避免了不可重复读和幻读的问题。


## 读加锁

如果我们的一些业务场景不允许读取记录的旧版本，而是每次都必须去读取记录的最新版本，比方在银行存款的事务中，
你需要先把账户的余额读出来，然后将其加上本次存款的数额，最后再写到数据库中。
在将账户余额读取出来后，就不想让别的事务再访问该余额，直到本次存款事务执行完成，其他事务才可以访问账户的余额。
这样在读取记录的时候也就需要对其进行 加锁 操作，这样也就意味着 读 操作和 写 操作也像 写-写 操作那样排队执行。


怎么解决 脏读 、 不可重复读 、 幻读 这些问题呢？其实有两种可选的解决方案：

- 方案一：读操作利用多版本并发控制（ MVCC ），写操作进行 加锁
- 方案二：读、写操作都采用 加锁 的方式。

## 脏读 不可重复读 幻读

我们说脏读的产生是因为当前事务读取了另一个未提交事务写的一条记录，如果另一个事务在写记录的时候就给这条记录加锁，那么当前事务就无法继续读取该记录了，所以也就不会有脏读问题的产生了。
不可重复读的产生是因为当前事务先读取一条记录，另外一个事务对该记录做了改动之后并提交之后，当前事务再次读取时会获得不同的值，如果在当前事务读取记录时就给该记录加锁，
那么另一个事务就无法修改该记录，自然也不会发生不可重复读了。我们说幻读问题的产生是因为当前事务读取了`一个范围的记录`，
然后另外的事务向该范围内插入了新记录，当前事务再次读取该范围的记录时发现了新插入的新记录，我们把新插入的那些记录称之为幻影记录。
采用加锁的方式解决幻读问题就有那么一丢丢麻烦了，因为当前事务在第一次读取记录时那些幻影记录并不存在，所以读取的时候加锁就有点尴尬 —— 因为你并不知道给谁加锁，
没关系，这难不倒设计InnoDB的大叔的，我们稍后揭晓答案，稍安勿躁。


## 一致性读（Consistent Reads）

事务利用 MVCC 进行的读取操作称之为 一致性读 ，或者 一致性无锁读 ，有的地方也称之为 快照读 。所有普通
的 SELECT 语句（ plain SELECT ）在 READ COMMITTED 、 REPEATABLE READ 隔离级别下都算是 一致性读 ，比方说：
```sql
SELECT * FROM t;
SELECT * FROM t1 INNER JOIN t2 ON t1.col1 = t2.col2
```
一致性读 并不会对表中的任何记录做 加锁 操作，其他事务可以自由的对表中的记录做改动。

## S锁 X锁

|兼容性| X | S |
|------|---|---|
|X  |不兼容|不兼容|
|S  |不兼容|兼容|

```sql
SELECT ... LOCK IN SHARE MODE;--  S锁
SELECT ... FOR UPDATE; -- X锁
```

## 表锁


给表加 S锁 ：

- 如果一个事务给表加了 S锁 ，那么：
- 别的事务可以继续获得该表的 S锁
- 别的事务可以继续获得该表中的某些记录的 S锁
- 别的事务不可以继续获得该表的 X锁
- 别的事务不可以继续获得该表中的某些记录的 X锁

给表加 X锁 ：

- 如果一个事务给表加了 X锁 （意味着该事务要独占这个表），那么：
- 别的事务不可以继续获得该表的 S锁
- 别的事务不可以继续获得该表中的某些记录的 S锁
- 别的事务不可以继续获得该表的 X锁
- 别的事务不可以继续获得该表中的某些记录的 X锁


## 意向锁

我们在对教学楼整体上锁（ 表锁 ）时，怎么知道教学楼中有没有教室已经被上锁（ 行锁 ）了呢？依次检查每一
间教室门口有没有上锁？那这效率也太慢了吧！遍历是不可能遍历的，这辈子也不可能遍历的，于是乎设计
InnoDB 的大叔们提出了一种称之为 意向锁 （英文名： Intention Locks ）的东东：
意向共享锁，英文名： Intention Shared Lock ，简称 IS锁 。当事务准备在某条记录上加 S锁 时，需要先
在表级别加一个 IS锁 。
意向独占锁，英文名： Intention Exclusive Lock ，简称 IX锁 。当事务准备在某条记录上加 X锁 时，需
要先在表级别加一个 IX锁 。


IS、IX锁是表级锁，它们的提出仅仅为了在之后加表级别的S锁和X锁时可以快速判断表中的记录是否
被上锁，以避免用遍历的方式来查看表中有没有上锁的记录，也就是说其实IS锁和IX锁是兼容的，IX锁和IX锁是
兼容的。


|兼容性| X | IX|  S| IS| 
-------|---|---|---|---|
|X | 不兼容 | 不兼容 | 不兼容 |不兼容
|IX| 不兼容 | 兼容   | 不兼容 | 兼容
|S | 不兼容 | 不兼容 | 兼容   | 兼容
|IS| 不兼容 | 兼容   | 兼容   |兼容

> 意向锁 可以认为是也标记锁，可以快速判断是否有锁的存在。

## 表级别的 IS锁 、 IX锁

当我们在对使用 InnoDB 存储引擎的表的某些记录加 S锁 之前，那就需要先在表级别加一个 IS锁 ，当我们在对使用 InnoDB 存储引擎的表的某些记录加 X锁 之前，那就需要先在表级别加一个 IX锁 。 IS锁 和 IX锁的使命只是为了后续在加表级别的 S锁 和 X锁 时判断表中是否有已经被加锁的记录，以避免用遍历的方式来查看表中有没有上锁的记录。更多关于 IS锁 和 IX锁 的解释我们上边都唠叨过了，就不赘述了。

## Gap Locks

我们说 MySQL 在 REPEATABLE READ 隔离级别下是可以解决幻读问题的，解决方案有两种，可以使用 MVCC 方案解决，也可以采用 加锁 方案解决。但是在使用 加锁 方案解决时有个大问题，就是事务在第一次执行读取操作时，那些幻影记录尚不存在，我们无法给这些幻影记录加上 正经记录锁 。不过这难不倒设计 InnoDB 的大叔，他们提出了一种称之为 Gap Locks 的锁，官方的类型名称为： LOCK_GAP ，我们也可以简称为 gap锁 。


这个 gap锁 的提出仅仅是为了防止插入幻影记录而提出的，虽然有 共享gap锁 和 独占gap锁 这样的说法，但是它们起到的作用都是相同的。而且如果你对一条记录加了 gap锁 （不论是 共享gap锁 还是 独占gap锁 ），并`不会限制`其他事务对这条记录加 正经记录锁 或者继续加 gap锁 ，再强调一遍， gap锁 的作用仅仅是为了防止插入幻影记录的而已。

- Infimum 记录，表示该页面中最小的记录。
- Supremum 记录，表示该页面中最大的记录。


## Next-Key Locks 

有时候我们既想锁住某条记录，又想阻止其他事务在该记录前边的 间隙 插入新记录，所以设计 InnoDB 的大叔们就提出了一种称之为 Next-Key Locks 的锁，官方的类型名称为： LOCK_ORDINARY ，我们也可以简称为next-key锁 。

next-key锁 的本质就是一个 正经记录锁 和一个 gap锁 的合体，它既能保护该条记录，又能阻止别的事务将新记录插入被保护记录前边的 间隙 。


## Insert Intention Locks 

我们说一个事务在插入一条记录时需要判断一下插入位置是不是被别的事务加了所谓的 gap锁 （ next-key锁 也包含 gap锁 ，后边就不强调了），如果有的话，插入操作需要等待，直到拥有 gap锁 的那个事务提交。但是设计 InnoDB 的大叔规定事务在等待的时候也需要在内存中生成一个 锁结构 ，表明有事务想在某个 间隙 中插入新记录，但是现在在等待。设计 InnoDB 的大叔就把这种类型的锁命名为 Insert IntentionLocks ，官方的类型名称为： LOCK_INSERT_INTENTION ，我们也可以称为 插入意向锁 。


事实上插入意向锁并不会阻止别的事务继续获取该记录上任何类型的锁（ 插入意向锁 就是这么鸡肋）。