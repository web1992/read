# mysql index

## index

InnoDB tables always have a clustered index representing the primary key

## covering index

An index that includes all the columns retrieved by a query. Instead of using the index values as pointers to find the full table rows, the query returns values from the index structure, saving disk I/O. InnoDB can apply this optimization technique to more indexes than MyISAM can, because InnoDB secondary indexes also include the primary key columns. InnoDB cannot apply this technique for queries against tables modified by a transaction, until that transaction ends.

Any column index or composite index could act as a covering index, given the right query. Design your indexes and queries to take advantage of this optimization technique wherever possible.

## clustered index

The InnoDB term for a `primary` `key` index. `InnoDB` table storage is organized based on the values of the primary key columns, to speed up queries and sorts involving the primary key columns. For best performance, choose the primary key columns carefully based on the most performance-critical queries. Because modifying the columns of the clustered index is an expensive operation, choose primary columns that are rarely or `never updated`.

In the Oracle Database product, this type of table is known as an index-organized table.

- [https://dev.mysql.com/doc/refman/5.7/en/glossary.html#glos_index](https://dev.mysql.com/doc/refman/5.7/en/glossary.html#glos_index)
