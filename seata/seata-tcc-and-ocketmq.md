# TCC + RocketMQ

把RocketMQ 的事物纳入Seata进行管理。

实现步骤：

1. RocketMQ 分支事物的注册（第一阶段）
2. RocketMQ 分支事物的提交和回滚（第二阶段

RocketMQ 在发送`事物消息`的时候,向Seata注册分支事物。在发消息成功之后，执行本地事物。
执行本地事物之后，根据本地事物的状态，发送commit 或者 rollback（事物结束）。
