# Branch

```java
@GlobalTransactional ->
    GlobalTransactionalInterceptor 
      -> handleGlobalTransaction
        -> TransactionalTemplate
                    -> execute
                    -> business.execute
                    -> DefaultGlobalTransaction.rollback / DefaultGlobalTransaction.commit ->
                        -> DefaultTransactionManager.rollback / DefaultTransactionManager.commit
                        -> GlobalRollbackRequest/GlobalCommitRequest
                        ↓
                        -> BranchRollbackRequest/BranchCommitRequest
```
