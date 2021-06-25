# DefaultCoordinator

TC 的核心实现类。

## 定时任务线程

| 线程                   | 任务                   | 周期                                             |
| ---------------------- | ---------------------- |
| 处理事物回滚的线程     | handleRetryRollbacking | 1000 ms 一次，可配置                             |
| 处理事物提交重试的线程 | handleRetryCommitting  | 1000 ms 一次，可配置                             |
| 处理异步提交的小吃     | handleAsyncCommitting  | 1000 ms 一次，可配置                             |
| 超时检查               | timeoutCheck           | 1000 ms 一次，可配置                             |
| 日志删除               | undoLogDelete          | `24 * 60 * 60 * 1000` ms  一次（24小时），可配置 |

`undoLogDelete` `AT` 模式下删除 `undoLog`

`timeoutCheck` 作用是把处于`Begin`状态的`GlobalSession`更新到 `RollbackRetrying` 状态。因为TM发送的回滚消息可能丢失。这里也是产生`空回滚`的原因。

因为TM在执行try之后就挂了(或者强制重启)，没有告诉全局事物的下一步操作（回滚还是提交）。全局事物超过之后，就会进入 RollbackRetrying 执行 rollback 操作。而try有两种CASE:

- try 成功：正常回滚
- try 失败：空回滚
