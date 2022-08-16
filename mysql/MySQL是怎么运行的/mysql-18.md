# 第18章 调节磁盘和CPU的矛盾-InnoDB的Buffer

- Buffer Pool 缓冲池
- innodb_buffer_pool_size
- 通过 free链表 （或者说空闲链表） 管理Buffer Pool
- 缓存页的哈希处理
- 脏页  dirty page
- 脏页的链表 flush链表
- LRU链表 缓存不够的窘境 Least Recently Used
- 缓存命中率
- read ahead
- innodb_read_ahead_threshold
- innodb_old_blocks_pct
- 尽量高效的提高 Buffer Pool 的缓存命中率
- 刷新脏页到磁盘
- BUF_FLUSH_LRU LRU链表
- BUF_FLUSH_LIST flush链表
- 多个Buffer Pool实例
- innodb_buffer_pool_chunk_size

## LRU

只要我们使用到某个缓存页，就把该缓存页调整到 LRU链表 的头部，这样 LRU链表 尾部就是最近最少使用的缓存页喽～ 所以当 Buffer Pool 中的空闲缓存页使用完时，到 LRU链表 的尾部找些缓存页淘汰就OK啦

## Buffer Pool

可能降低 Buffer Pool 的两种情况：
加载到 Buffer Pool 中的页不一定被用到。
如果非常多的使用频率偏低的页被同时加载到 Buffer Pool 时，可能会把那些使用频率非常高的页从
Buffer Pool 中淘汰掉。

因为有这两种情况的存在，所以设计 InnoDB 的大叔把这个 LRU链表 按照一定比例分成两截，分别是：
一部分存储使用频率非常高的缓存页，所以这一部分链表也叫做 热数据 ，或者称 young区域 。
另一部分存储使用频率不是很高的缓存页，所以这一部分链表也叫做 冷数据 ，或者称 old区域 。

1. 磁盘太慢，用内存作为缓存很有必要。
2. Buffer Pool 本质上是 InnoDB 向操作系统申请的一段连续的内存空间，可以通过innodb_buffer_pool_size 来调整它的大小。
3. Buffer Pool 向操作系统申请的连续内存由控制块和缓存页组成，每个控制块和缓存页都是一一对应的，在
填充足够多的控制块和缓存页的组合后， Buffer Pool 剩余的空间可能产生不够填充一组控制块和缓存页，
这部分空间不能被使用，也被称为 碎片 。 4. InnoDB 使用了许多 链表 来管理 Buffer Pool 。
5. free链表 中每一个节点都代表一个空闲的缓存页，在将磁盘中的页加载到 Buffer Pool 时，会从 free链表 中寻找空闲的缓存页。
6. 为了快速定位某个页是否被加载到 Buffer Pool ，使用 表空间号 + 页号 作为 key ，缓存页作为 value ，建立哈希表。
7. 在 Buffer Pool 中被修改的页称为 脏页 ，脏页并不是立即刷新，而是被加入到 flush链表 中，待之后的某个时刻同步到磁盘上。
8. LRU链表 分为 young 和 old 两个区域，可以通过 innodb_old_blocks_pct 来调节 old 区域所占的比例。首次从磁盘上加载到 Buffer Pool 的页会被放到 old 区域的头部，在 innodb_old_blocks_time 间隔时间内访问该页不会把它移动到 young 区域头部。在 Buffer Pool 没有可用的空闲缓存页时，会首先淘汰掉 old 区域的一些页。
9. 我们可以通过指定 innodb_buffer_pool_instances 来控制 Buffer Pool 实例的个数，每个 Buffer Pool 实例中都有各自独立的链表，互不干扰。
10. 自 MySQL 5.7.5 版本之后，可以在服务器运行过程中调整 Buffer Pool 大小。每个 Buffer Pool 实例由若干个 chunk 组成，每个 chunk 的大小可以在服务器启动时通过启动参数调整。
11. 可以用下边的命令查看 Buffer Pool 的状态信息：SHOW ENGINE INNODB STATUS\G