# Branch

```java
@GlobalTransactional ->
    GlobalTransactionalInterceptor 
      -> handleGlobalTransaction
        -> TransactionalTemplate
           -> execute
               -> GlobalTransaction
                 -> TransactionManager
                    -> GlobalBeginRequest
                      -> business.execute
                      -> DefaultGlobalTransaction.rollback / DefaultGlobalTransaction.commit ->
                          -> DefaultTransactionManager.rollback / DefaultTransactionManager.commit
                          -> GlobalRollbackRequest/GlobalCommitRequest
                          ↓
                          TC
                          ↓
                          -> BranchRollbackRequest/BranchCommitRequest
```

## TCCResourceManager

TCC  模式下，`BranchRollbackRequest` 的处理在 `TCCResourceManager#branchRollback`方法中。

`BranchCommitRequest` 的处理在 `TCCResourceManager#branchCommit`方法中。
