# 第四章 表

- 索引组织表
- _rowid 主键列
- 表空间
- 段
- 区大小 1m （由一系列的页组成）
- 页大小 16k
- 32 个碎页
- Compact 
- Redundant
- BLOB LOB 类型的数据会进行特殊的处理
- Infimum ， Supremum Record
- User Record FA Free Space
- 约束
- 索引
- sql_mode  STRICT_TRANS_TABLES
- RANGE 分区
- LIST 分区
- HASH 分区
- KEY 分区


## _rowid

另外需要注意的是，_rowid 只能用于查看单个列为主键的情况，对于多列组成的主键就显得无能为力了。

## InnoDB逻辑存储结构

![mysql-innodb-chapter-04-01.drawio.svg](./images/mysql-innodb-chapter-04-01.drawio.svg)

## 表空间

表空间可以看做是InnoDB存储引擎逻辑结构的最高层，所有的数据都存放在表空间中。第3章中已经介绍了在默认情况下InnoDB存储引擎有一个共享表空间ibdata1,
即所有数据都存放在这个表空间内。如果用户启用了参数innodb_file_per_table, 则每张表内的数据可以单独放到一个表空间内。
如果启用了innodb_file_per_table 的参数，需要注意的是每张表的表空间内存放的只是数据、索引和插人缓冲Bitmap页，其他类的数据，如回滚(undo) 信息，插入缓冲
索引页、系统事务信息，二次写缓冲(Double write buffer)等还是存放在原来的共享表空间内。这同时也说明了另一个问题:即使在启用了参数innodb_file_per_table之后，共
享表空间还是会不断地增加其大小。

## 段

图4-1中显示了表空间是由各个段组成的，常见的段有数据段、索引段、回滚段等。因为前面已经介绍过了`InnoDB`存储引擎表是索引组织的(index organized)，因此数据
即索引，索引即数据。那么数据段即为B+树的叶子节点(图4-1的Leaf node segment),索引段即为B+树的非索引节点(图4-1的Non-leaf node segment)。回滚段较为特殊，将会在后面的章节进行单独的介绍。

## 区

区是由连续页组成的空间，在任何情况下每个区的大小都为1MB.为了保证区中页的连续性，InnoDB 存储引擎一次从磁盘申请4 ~ 5个区。在默认情况下，InnoDB存储引擎页的大小为16KB，即一个区中一共有64个连续的页。

## 页

同大多数数据库一样，InnoDB 有页(Page) 的概念(也可以称为块)，页是InnoDB磁盘管理的最小单位。在InnoDB存储引擎中，默认每个页的大小为16KB。而从InnoDB1.2.x版本开始，可以通过参数innodb_page_size将页的大小设置为4K、8K、16K。若设置完成，则所有表中页的大小都为innodb_page_size， 不可以对其再次进行修改。除非通过`mysqldump`导人和导出操作来产生新的库。

在InnoDB存储引擎中，常见的页类型有:

- 数据页(B-tree Node)
- undo页(undo Log Page)
- 系统页(System Page)
- 事务数据页(Transaction system Page)
- 插人缓冲位图页(Insert Buffer Bitmap)
- 插人缓冲空闲列表页(Insert Buffer Free List)
- 未压缩的二进制大对象页(Uncompressed BLOB Page)
- 压缩的二进制大对象页(compressed BLOB Page)

## 行

InnoDB存储引擎是面向列的(row- oriented)，也就说数据是按行进行存放的。每个页存放的行记录也是有硬性定义的，最多允许存放16KB/2-200行的记录，即7992行记录。这里提到了`row-oriented`的数据库，也就是说，存在有column-oriented的数据库。

MySQL infobright 存储引擎就是按列来存放数据的，这对于数据仓库下的分析类SQL语句的执行及数据压缩非常有帮助。类似的数据库还有Sybase IQ、Google Big Table。

## InnoDB行记录格式

- Compact 
- Redundant

```sql
show  table status  like '%my_table%';
```

## Compact行记录格式

![mysql-innodb-chapter-04-02.drawio.svg](./images/mysql-innodb-chapter-04-02.drawio.svg)

最后的部分就是实际存储每个列的数据。需要特别注意的是，NULL不占该部分任何空间，即NULL除了占有NULL标志位，实际存储不占有任何空间。另外有一点需要
注意的是，每行数据除了用户定义的列外，还有两个隐藏列，事务ID列和回滚指针列,分别为6字节和7字节的大小。若InnoDB表没有定义主键，每行还会增加一个6字节的rowid列。

现在第一行数据就展现在用户眼前了。需要注意的是，变长字段长度列表是逆序存
放的，因此变长字段长度列表为03 02 01， 而不是01 02 03。此外还需要注意InnoDB每
行有隐藏列TransactionID和Roll Pointer。 同时可以发现，固定长度CHAR字段在未能
完全占用其长度空间时，会用0x20来进行填充。

不管是CHAR类型还是VARCHAR类型，在compact格式下NULL都不占用任何存储空间。

## Redundant 行记录格式

可以看到对于VARCHAR类型的NULL值，Redundant 行记录格式同样不占用任何存储空间，而CHAR类型的NULL值需要占用空间。

当前表mytest2的字符集为Latin1，每个字符最多只占用1字节。若用户将表mytest2的字符集转换为utf8，第三列CHAR固定长度类型不再是只占用10字节了，而
是10X3=30字节。所以在Redundant行记录格式下，CHAR类型将会占用可能存放的最大值字节数。有兴趣的读者可以自行尝试。

![mysql-innodb-chapter-04-03.drawio.svg](./images/mysql-innodb-chapter-04-03.drawio.svg)

## 行溢出数据

![mysql-innodb-chapter-04-04.drawio.svg](./images/mysql-innodb-chapter-04-04.drawio.svg)

InnoDB存储引擎可以将一条记录中的某些数据存储在真正的数据页面之外。一般认为BLOB、LOB这类的大对象列类型的存储会把数据存放在数据页面之外。但是，这个
理解有点偏差, BLOB可以不将数据放在溢出页面，而且即便是VARCHAR列数据类型，依然有可能被存放为行溢出数据。

首先对VARCHAR数据类型进行研究。很多DBA喜欢MySQL数据库提供的VARCHAR类型，因为相对于Oracle VARCHAR2最大存放4000字节，SQL Server最大
存放8000字节，MySQL数据库的VARCHAR类型可以存放65535字节。但是，这是真的吗?真的可以存放65535字节吗?如果创建VARCHAR长度为65535的表，用户会得到下面的错误信息:

```sql
CREATE TABLE test (
 a VARCHAR(65535)

) CHARSET=latin1 ENGINE= InnoDB;

11:59:11	CREATE TABLE test (  a VARCHAR(65535)  ) CHARSET=latin1 ENGINE= InnoDB	Error Code: 1118. Row size too large. The maximum row size for the used table type, not counting BLOBs, is 65535. This includes storage overhead, check the manual. You have to change some columns to TEXT or BLOBs	0.045 sec

```

从错误消息可以看到InnoDB存储引擎并不支持65535长度的VARCHAR。这是因为还有别的开销，通过实际测试发现能存放VARCHAR类型的最大长度为65532.

这次即使创建列的VARCHAR长度为65532,也会提示报错,但是两次报错对max值的提示是不同的。因此从这个例子中用户也应该理解VARCHAR (N)中的N指的是字符的长度。而文档中说明VARCHAR类型最大支持65535，单位是字节。

此外需要注意的是，MySQL官方手册中定义的65535长度是指所有VARCHAR列”的长度总和，如果列的长度总和超出这个长度，依然无法创建，如下所示:

3个列长度总和是66000，因此InnoDB存储引擎再次报了同样的错误。即使能存放65532个字节，但是有没有想过，InnoDB 存储引擎的页为16KB，即16384 字节，怎么
能存放65532字节呢?因此，在--般情况下，InnoDB存储引擎的数据都是存放在页类型为B-treenode中。但是当发生行溢出时，数据存放在页类型为UncompressBLOB页中。

## Compressed和Dynamic行记录格式

InnoDB 1.0.x 版本开始引入了新的文件格式(file format,用户可以理解为新的页格式),以前支持的Compact和Redundant格式称为Antelope 文件格式，新的文件格式称为Barracuda文件格式。Barracuda 文件格式下拥有两种新的行记录格式: Compressed 和Dynamic.

新的两种记录格式对于存放在BLOB中的数据采用了完全的行溢出的方式，如图4-5所示，在数据页中只存放20个字节的指针，实际的数据都存放在OffPage中，而之前的Compact和Redundant两种格式会存放768个前缀字节。

Compressed行记录格式的另一个功能就是，存储在其中的行数据会以zlib的算法进行压缩，因此对于BLOB、TEXT、VARCHAR这类大长度类型的数据能够进行非常有效的存储。

![mysql-innodb-chapter-04-05.drawio.svg](./images/mysql-innodb-chapter-04-05.drawio.svg)

## CHAR的行结构存储

然而，值得注意的是之前给出的两个例子中的字符集都是单字节的latin1格式。从MySQL 4.1版本开始, CHR(N)中的N指的是字符的长度，而不是之前版本的字节长度。
也就说在不同的字符集下，CHAR类型列内部存储的可能不是定长的数据。

## InnoDB数据页

InnoDB数据页由以下7个部分组成，如图4-6所示。

- File Header (文件头)
- Page Header (页头)
- Infimun和Supremum Records
- User Records (用户记录，即行记录)
- Free Space (空闲空间)
- Page Directory (页目录) 
- File Trailer (文件结尾信息)
