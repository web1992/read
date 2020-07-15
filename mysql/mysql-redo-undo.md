# redo & undo

## redo log

redo log 重做日志 用来保证事务的原子性和持久性。

redo log 恢复的是提交事务修改的页操作

redo log 是物理日志，记录的是页的物理修改操作

## undo log

用来保证事务的一致性

undo log 回滚行记录到指定的版本

undo log 是逻辑日志 根据每行进行记录