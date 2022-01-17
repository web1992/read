# mysql lock

- 锁级别： 表级锁 页级锁 行级锁
- 锁分类：行锁 共享锁（S) 排它锁（X）,表锁：意向共享锁(IS)，意向排他锁（IX），自增锁
- 单当记录的锁（锁数据，不锁Gap）record lock
- 间隙锁，锁一个范围，不包括记录本身 gap lock
- 同时锁住数据，并且锁住数据前面的Gap
- 主键+RR： 主键索引记录上加X锁
- 唯一索引（id=10）+ RR：先在唯一索引上id 加X lock 再在id= 10的主键索引记录上加X锁，id=10 不存在，加gap锁
- 非唯一索引加锁 +RR
- 无索引+RR:表里所有行和间隙均加X lock
-  metadata lock 云数据锁

## Links

- [https://tech.meituan.com/2014/08/20/innodb-lock.html](https://tech.meituan.com/2014/08/20/innodb-lock.html)

