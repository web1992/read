# 第21章 说过的话就一定要办到-redo日志（下）

- redo日志文件
- redo日志刷盘时机
- innodb_log_buffer_size
- redo日志文件组
- SHOW VARIABLES LIKE 'datadir'
- ib_logfile0 和 ib_logfile1

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