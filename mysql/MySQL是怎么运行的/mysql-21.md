# 第21章 说过的话就一定要办到-redo日志（下）

- redo日志文件
- redo日志刷盘时机
- innodb_log_buffer_size
- redo日志文件组
- SHOW VARIABLES LIKE 'datadir'
- ib_logfile0 和 ib_logfile1 redo日志文件
- 循环使用redo日志文件
- checkpoint
- Log Sequeue Number 的全局变量（日志序列号）
- flushed_to_disk_lsn
- buf_next_to_write
- write_lsn
- flush链表
- checkpoint_lsn
- checkpoint_no
- LRU链表 和 flush链表
- SHOW ENGINE INNODB STATUS 可以查询 lsn 相关的信息
- innodb_flush_log_at_trx_commit的用法
- 

## redo日志刷盘时机

- log buffer 空间不足时
    log buffer 的大小是有限的（通过系统变量innodb_log_buffer_size 指定），如果不停的往这个有限大小
    的log buffer 里塞入日志，很快它就会被填满。设计InnoDB 的大叔认为如果当前写入log buffer 的
    redo 日志量已经占满了log buffer 总容量的大约一半左右，就需要把这些日志刷新到磁盘上。
- 事务提交时
    我们前边说过之所以使用redo 日志主要是因为它占用的空间少，还是顺序写，在事务提交时可以不把修改
    过的Buffer Pool 页面刷新到磁盘，但是为了保证持久性，必须要把修改这些页面对应的redo 日志刷新到磁盘。
- 后台线程不停的刷刷刷
    后台有一个线程，大约每秒都会刷新一次log buffer 中的redo 日志到磁盘。
- 正常关闭服务器时
- 做所谓的checkpoint 时（我们现在没介绍过checkpoint 的概念，稍后会仔细唠叨，稍安勿躁）
- 其他的一些情况...

## redo log 日志文件

- innodb_log_group_home_dir
该参数指定了 redo 日志文件所在的目录，默认值就是当前的数据目录。
- innodb_log_file_size
该参数指定了每个 redo 日志文件的大小，在 MySQL 5.7.21 这个版本中的默认值为 48MB ，
- innodb_log_files_in_group
该参数指定 redo 日志文件的个数，默认值为2，最大值为100。

## flushed_to_disk_lsn

lsn 是表示当前系统中写入的 redo 日志量，这包括了写到 log buffer 而没有刷新到磁盘的日志，
相应的，设计 InnoDB 的大叔提出了一个表示刷新到磁盘中的 redo 日志量的全局变量，称之为
flushed_to_disk_lsn 。系统第一次启动时，该变量的值和初始的 lsn 值是相同的，都是 8704 。随着系统的运
行， redo 日志被不断写入 log buffer ，但是并不会立即刷新到磁盘， lsn 的值就和 flushed_to_disk_lsn 的
值拉开了差距。

当有新的 redo 日志写入到 log buffer 时，首先 lsn 的值会增长，但 flushed_to_disk_lsn 不变，
随后随着不断有 log buffer 中的日志被刷新到磁盘上， flushed_to_disk_lsn 的值也跟着增长。如果两者的值
相同时，说明log buffer中的所有redo日志都已经刷新到磁盘中了。

应用程序向磁盘写入文件时其实是先写到操作系统的缓冲区中去，如果某个写入操作要等到操作系统确
认已经写到磁盘时才返回，那需要调用一下操作系统提供的fsync函数。其实只有当系统执行了fsync函
数后，flushed_to_disk_lsn的值才会跟着增长，当仅仅把log buffer中的日志写入到操作系统缓冲区
却没有显式的刷新到磁盘时，另外的一个称之为write_lsn的值跟着增长。不过为了大家理解上的方
便，我们在讲述时把flushed_to_disk_lsn和write_lsn的概念混淆了起来。

## checkpoint

有一个很不幸的事实就是我们的 redo 日志文件组容量是有限的，我们不得不选择循环使用 redo 日志文件组中的
文件，但是这会造成最后写的 redo 日志与最开始写的 redo 日志 追尾 ，这时应该想到：redo日志只是为了系统
奔溃后恢复脏页用的，如果对应的脏页已经刷新到了磁盘，也就是说即使现在系统奔溃，那么在重启后也用不着
使用redo日志恢复该页面了，所以该redo日志也就没有存在的必要了，那么它占用的磁盘空间就可以被后续的
redo日志所重用。也就是说：判断某些redo日志占用的磁盘空间是否可以覆盖的依据就是它对应的脏页是否已经
刷新到磁盘里。

- 全局变量 checkpoint_lsn 来代表当前系统中可以被覆盖的 redo 日志总量是多少
- 做一次 checkpoint 增加 checkpoint_lsn 的操作
- 