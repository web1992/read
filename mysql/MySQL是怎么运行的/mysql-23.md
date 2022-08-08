# 第23章 后悔了怎么办-undo日志（下）

- 通用链表结构
- Pre Node Page Number 和 Pre Node Offset 的组合就是指向前一个节点的指针
- Next Node Page Number 和 Next Node Offset 的组合就是指向后一个节点的指针
- List Base Node
- FIL_PAGE_UNDO_LOG页面 Undo页面
- Undo页面链表
- first undo page 
- normal undo page
- 单个事务中的Undo页面链表
- 多个事务中的Undo页面链表
- 段（Segment）的概念
- Segment Header
- Undo Log Segment Header
- Undo Log Header
- 重用Undo页面
- 回滚段
- Rollback Segment Header
- Rollback Segment
- 入 insert undo cached链表
- 入 insert undo cached链表
- undo slot
- innodb_rollback_segments  回滚段数量配置
- 

## 单个事务中的Undo页面链表

因为一个事务可能包含多个语句，而且一个语句可能对若干条记录进行改动，而对每条记录进行改动前，都需要
记录1条或2条的 undo日志 ，所以在一个事务执行过程中可能产生很多 undo日志 ，这些日志可能一个页面放不
下，需要放到多个页面中，这些页面就通过我们上边介绍的 TRX_UNDO_PAGE_NODE 属性连成了链表

##  Segment Header 

整个 Segment Header 占用10个字节大小，各个属性的意思如下：
Space ID of the INODE Entry ： INODE Entry 结构所在的表空间ID。
Page Number of the INODE Entry ： INODE Entry 结构所在的页面页号。
Byte Offset of the INODE Ent ： INODE Entry 结构在该页面中的偏移量

