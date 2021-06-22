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

- `undoLogDelete` `AT` 模式下删除 `undoLog`
- `timeoutCheck` 清理过时的 `GlobalSession`（全局事物的过期失效，默认是60000ms）由TM的参数(`client.tm.default-global-transaction-timeout`)决定
