# es 查询

-  Query Context and Filter Context

## Multi Query

多字段查询: Multi Match

三种场景

- 最佳字段(Best Fields)
当字段之间相互竞争，又相互关联。例如title 和body这样的字段。评分来自最匹配字段

- 多数字段(Most Fields)
处理英文内容时: 一种常见的手段是，在主字段( English Analyzer), 抽取词干，加入同义词，以匹配更多的文档。相同的文本，加入子字段(Standard Analyzer)，以提供更加精确的匹配。其他字段作为匹配文档提高相关度的信号。匹配字段越多则越好

- 混合字段(Cross Field)
对于某些实体， 例如人名，地址，图书信息。需要在多个字段中确定信息，单个字段只能作为整体的一部分。希望在任何这些列出的字段中找到尽可能多的词