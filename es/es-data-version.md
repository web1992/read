# ES 数据更新


ES中的文档是不可变更的。如果你更新一个文档，会将就文档标记为删除，同时增加一个全新的文档。同时文档的version字段加1

内部版本控制.
- If_seq_no + If_primary_term

使用外部版本(使用其他数据库作为主要数据存储)
- version + version_type=external

## Links

- [If_seq_no + If_primary_term](https://developer.aliyun.com/article/789071)