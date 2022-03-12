# Seata 状态机

## Commit 失败

下图是`commit`失败的`状态机`变化

![seata-commit-failed.drawio.svg](./images/seata-commit-failed.drawio.svg)

`commit`失败，会进入到`handleRetryCommitting`循环中，会导致Seata服务一直调用RM服务，并且频率很高。这里需要特殊处理。需要加监控，防止服务被打挂了。

## Rollback 失败

下图是`rollback`失败的`状态机`变化

![seata-rollback-failed.drawio.svg](./images/seata-rollback-failed.drawio.svg)

rollback失败也会进入到`handleRetryRollbacking`循环中，会导致Seata服务一直调用RM服务，并且频率很高。这里需要特殊处理。需要加监控，防止服务被打挂了。

## Try 失败

下图是try失败的`状态机`变化

![seata-try-failed.drawio.svg](./images/seata-try-failed.drawio.svg)
