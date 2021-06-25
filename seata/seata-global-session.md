# GlobalSession

## GlobalSession timeout

GlobalSession 的 timeout 参数控制。

```java
public class GlobalSession implements SessionLifecycle, SessionStorable {
    private int timeout; 
}
```

首先此参数是由 TM 在创建事物的时候，已经确定的，默认是 60000ms。此外`DefaultCoordinator`存在一个 `DefaultCoordinator#timeoutCheck` 的任务检查是否超时。

`timeout`可以通过`client.tm.defaultGlobalTransactionTimeout`参数控制。

```java
for (GlobalSession globalSession : allSessions) {
 
    // 加锁
    boolean shouldTimeout = SessionHolder.lockAndExecute(globalSession, () -> {
        // 执行在状态=Begin 并且超时了才会 返回true
        if (globalSession.getStatus() != GlobalStatus.Begin || !globalSession.isTimeout()) {
            return false;
        }
        globalSession.addSessionLifecycleListener(SessionHolder.getRootSessionManager());
        globalSession.close();
        globalSession.changeStatus(GlobalStatus.TimeoutRollbacking);
        return true;
    });
    if (!shouldTimeout) {
        continue;
    }
    globalSession.addSessionLifecycleListener(SessionHolder.getRetryRollbackingSessionManager());
    // 把此 session 的加入RetryRollbackingSession列表中。
    SessionHolder.getRetryRollbackingSessionManager().addGlobalSession(globalSession);
}

// GlobalSession#isTimeout
public boolean isTimeout() {
    return (System.currentTimeMillis() - beginTime) > timeout;
}
```

为什么需要此参数？以为存在 TM 捕获到异常的情况，会驱动全局事物进行回滚。也就是与 `GlobalSession` 关联的全局事物。但是由于网络问题，此消息TC没有收到。
因此可能导致此全局事物一直是 `Begin` 状态。因此需要此 `timeoutCheck+timeout` 来处理此种情况。
