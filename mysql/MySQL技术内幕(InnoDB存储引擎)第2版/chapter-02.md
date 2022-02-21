# 第2章 InnoDB存储引擎

- 后台线程
- 缓冲池
- Master Thread
- IO Thread
- insert buffer thread
- log thread
- read thread
- write therad
- Purge Thread 回收 undo 页
- Page cleaner Thread
- innodb_buffer_pool_size 缓冲池配置
- double write (两次写)

## Master Thread

Master Thread是一个非常核心的后台线程，主要负责将缓冲池中的数据异步刷新到磁盘，保证数据的一致性，
包括脏页的新、合并插人缓冲(INSERT BUFFER)、UNDO页的回收等。2.5 节会详细地介绍各个版本中Master Thread的工方式。

## 缓冲池

InnoDB存储引擎是基于磁盘存储的，并将其中的记录按照页的方式进行管理。因此
可将其视为基于磁盘的数据库系统(Disk-base Database)。在数据库系统中，由于CPU
速度与磁盘速度之间的鸿沟，基于磁盘的数据库系统通常使用缓冲池技术来提高数据库的整体性能。

缓冲池简单来说就是一块内存区域，通过内存的速度来弥补磁盘速度较慢对数据库性能的影响。在数据库中进行读取页的操作，首先将从磁盘读到的页存放在缓冲池中,
这个过程称为将页`FIX`在缓冲池中。下一次再读相同的页时，首先判断该页是否在缓冲池中。若在缓冲池中，称该页在缓冲池中被命中，直接读取该页。否则，读取磁盘上的页。

对于数据库中页的修改操作，则首先修改在缓冲池中的页，然后再以一定的频率刷新到磁盘上。这里需要注意的是，页从缓冲池刷新回磁盘的操作并不是在每次页发生更
新时触发，而是通过一种称为`Checkpoint`的机制刷新回磁盘。同样，这也是为了提高数据库的整体性能。

## Innodb 的关键技术

InnoDB存储引擎的关键特性包括:

- 插人缓冲(Insert Buffer)
- 两次写(Double Write)
- 自适应哈希索引(Adaptive Hash Index )
- 异步IO (Async IO)
- 刷新邻接页(Flush Neighbor Page)

上述这些特性为InnoDB存储引擎带来更好的`性能`以及更高的`可靠性`。


## 两次写

如果说Insert Buffer带给InnoDB存储弓|擎的是性能上的提升，那么double write (两次写)带给InnoDB存储引擎的是数据页的可靠性。

当发生数据库宕机时，可能InnoDB存储引擎正在写人某个页到表中，而这个页只写了一部分，比如16KB的页，只写了前4KB，之后就发生了宕机，这种情况被称为部
分写失效(partial page write)。在InnoDB存储引擎未使用double write 技术前，曾经出现过因为部分写失效而导致数据丢失的情况。

有经验的DBA也许会想，如果发生写失效，可以通过重做日志进行恢复。这是一个办法。但是必须清楚地认识到，重做日志中记录的是对页的物理操作，如偏移量800,
写'aaaa' 记录。如果这个页本身已经发生了损坏，再对其进行重做是没有意义的。这就是说，在应用(apply) 重做日志前，用户需要一个页的副本，当写人失效发生时，先
通过页的副本来还原该页，再进行重做，这就是double write。在InnoDB存储引擎中double write的体系架构如图2-5所示。

double write由两部分组成，一部分是内存中的doubl ewrite buffer,大小为2MB，另一部分是物理磁盘上共享表空间中连续的128个页，即2个区(extent)，大小同样为2MB。在对缓冲池的脏页进行刷新时，并不直接写磁盘，而是会通过memcpy函数将脏页先复制到内存中的double write buffer,之后通过double write buffer再分两次，每次
1MB顺序地写人共享表空间的物理磁盘上，然后马上调用fsync函数，同步磁盘，避免缓冲写带来的问题。在这个过程中，因为double write页是连续的，因此这个过程是顺序
写的，开销并不是很大。在完成double write页的写人后，再将double write buffer中的页写人各个表空间文件中，此时的写人则是离散的。

![mysql-innodb-chapter-02-05.drawio.svg](./images/mysql-innodb-chapter-02-05.drawio.svg)

如果操作系统在将页写人磁盘的过程中发生了崩溃，在恢复过程中，InnoDB 存储引擎可以从共享表空间中的double write中找到该页的一个副本，将其复制到表空间文件,再应用重做日志。

## Links

- [https://www.cnblogs.com/geaozhang/p/7241744.html](https://www.cnblogs.com/geaozhang/p/7241744.html)