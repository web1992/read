# xa

- Resource Managers
- Transaction Manager

A Resource Manager (`RM`) provides access to transactional resources. A database server is one kind of resource manager. It must be possible to either commit or roll back transactions managed by the RM.

A Transaction Manager (`TM`) coordinates the transactions that are part of a global transaction. It communicates with the RMs that handle each of these transactions. The individual transactions within a global transaction are “branches” of the global transaction. Global transactions and their branches are identified by a naming scheme described later.

The MySQL implementation of `XA` enables a MySQL server to act as a Resource Manager that handles `XA` transactions within a global transaction. A client program that connects to the MySQL server acts as the Transaction Manager.

- [https://dev.mysql.com/doc/refman/5.7/en/xa.html](https://dev.mysql.com/doc/refman/5.7/en/xa.html)
