# 第5章 日志存储

- Log 和LogSegment
- .log 文件
- .index 文件 偏移量索引文件
- .timeindex 文件 时间戳索引文件
- 其他文件
- 当前活跃的日志分段
- 建新的activeSegment
- Message Set
- 消息压缩 compression.type
- Varints编码极大地节省了空间

## LogSegment

每个 LogSegment 都有一个基准偏移量 baseOffset，用来表示当前 LogSegment中第一条消息的offset。偏移量是一个64位的长整型数，日志文件和两个索引文件都是根据基准偏移量（baseOffset）命名的，名称固定为20位数字，没有达到的位数则用0填充。比如第一个LogSegment的基准偏移量为0，对应的日志文件为00000000000000000000.log。