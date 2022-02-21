# 第三章 文件

- 参数文件
- 日志文件
- 二进制文件 binary log
- 重做日志文件
- 慢查询日志
- 查询日志文件
- MySQL 表结构文件
- 存储引擎文件


## 二进制文件

- 恢复 recovery
- 复制 replication
- 审计 audit
- binlog_format： statement 格式 ，ROW 格式 ，MIX 格式
- ROW 格式 占用的磁盘日志比较大，增加复制的网络开销

(1) STATEMENT格式和之前的MySQL版本-样，二进制日志文件记录的是日志的逻辑SQL语句。

(2)在ROW格式下，二进制日志记录的不冉是间早的SQL语句了，而是记录表的行更改情况。基于ROW格式的复制类似于Oracle的物理Standby(当然，还是有些区别)。同时，对上述提及的Statement格式下复制的问题予以解决。从MySQL 5.1版本开始，如果设置了binlog_format为ROW,可以将InnoDB的事务隔离基本设为READ COMMITTED，以获得更好的并发性。

(3)在MIXED格式下，MySQL默认采用 STATEMENT 格式进行二进制日志文件的记录，但是在一些情况下会使用ROW格式，可能的情况有:
- 1)表的存储引擎为NDB，这时对表的DML操作都会以ROW格式记录。
- 2)使用了UUID())、USER()、CURRENT() USER()、FOUND ROWSO、ROW_COUNTO等不确定函数。
- 3)使用了INSERT DELAY语句。
- 4)使用了用户定义函数(UDF)。
- 5)使用了临时表(temporary table)。

## 表结构的文件

- 重做日志文件
- 表空间文件
- .ibd 文件 独立表空间
- .frm 文件
- innodb_file_per_table=ON

InnoDB采用将存储的数据按表空间(tablespace)进行存放的设计。在默认配置下会有一个初始大小为10MB,名为ibdata1的文件。

![mysql-innodb-chapter-03-01.drawio.svg](./images/mysql-innodb-chapter-03-01.drawio.svg)

## 重做日志文件

在默认情况下，在InnoDB存储引擎的数据目录下会有两个名为ib_ logfile0 和ib_logfile1的文件。在MySQL官方手册中将其称为InnoDB存储引擎的日志文件，不过更
准确的定义应该是重做日志文件(redo log fle)。为什么强调是重做日志文件呢?因为重做日志文件对于InnoDB存储引擎至关重要，它们记录了对于InnoDB存储引擎的`事务日志`。
当实例或介质失败(media failure)时，重做日志文件就能派上用场。例如，数据库由于所在主机掉电导致实例失败，InnoDB存储引擎会使用重做日志恢复到掉电前的时刻，以此来保证数据的完整性。

也许有人会问，既然同样是记录事务日志，和之前介绍的二进制日志有什么区别?

首先，二进制日志会记录所有与MySQL数据库有关的日志记录，包括InnoDB、MyISAM、Heap等其他存储引擎的日志。而InnoDB存储引擎的重做日志只记录有关该存储引擎本身的事务日志。

其次，记录的内容不同，无论用户将二进制日志文件记录的格式设为STATEMENT还是ROW，又或者是MIXED,其记录的都是关于一个事务的具体操作内容，即该日志是`逻辑日志`。而InnoDB存储引擎的重做日志文件记录的是关于每个页(Page) 的更改的`物理`情况。

此外，写人的时间也不同，二进制日志文件仅在`事务提交前进行提交`，即只写磁盘一次，不论这时该事务多大。而在事务进行的过程中，却不断有重做日志条目(redo entry)被写人到重做日志文件中。


![mysql-innodb-chapter-03-02.drawio.svg](./images/mysql-innodb-chapter-03-02.drawio.svg)

从表3-2可以看到重做日志条目是由4个部分组成:

- redo_log_type 占用1字节，表示重做日志的类型space表示表空间的ID，但采用压缩的方式，因此占用的空间可能小于4字节
- page_no 表示页的偏移量，同样采用压缩的方式
- redo_log_body 表示每个重做日志的数据部分，恢复时需要调用相应的函数进行解析

![mysql-innodb-chapter-03-03.drawio.svg](./images/mysql-innodb-chapter-03-03.drawio.svg)

从重做日志缓冲往磁盘写入时，是按512个字节，也就是一个扇区的大小进行写人。因为扇区是写入的最小单位，因此可以保证写人必定是成功的。因此在重做日志的写人过程中不需要有 double write。

参数`innodb_fush_log_at_trx_commit`的有效值有0、1、2。
- 0代表当提交事务时，并不将事务的重做日志写人磁盘上的日志文件，而是等待主线程每秒的刷新。1和2不同的地方在于。
- 1表示在执行commit时将重做日志缓冲同步写到磁盘，即伴有fsync的调用。
- 2表示将重做日志异步写到磁盘，即写到文件系统的缓存中。因此不能完全保证在执行commit时肯定会写入重做日志文件，只是有这个动作发生。

因此为了保证事务的ACID中的持久性，必须将`innodb_flush_log_at_trx_commit`设置为1,也就是每当有事务提交时，就必须确保事务都已经写人重做日志文件。那么当数据库因为意外发生宕机时，可以通过重做日志文件恢复，并保证可以恢复已经提交的事务。而将重做日志文件设置为0或2，都有可能发生恢复时部分事务的丢失。
不同之处在于，设置为2时，当MySQL数据库发生宕机而操作系统及服务器并没有发生宕机时，由于此时未写入磁盘的事务日志保存在文件系统缓存中，当恢复时同样能保证数据不丢失。
