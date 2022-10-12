# ES 核心

- ES VS DB
- ES 概念
- ES 分片 Primary Shard & Replica Shard
- 集群状态

## 分片

对于生产环境中分片的设定，需要提前做好容量规划

- 分片数设置过小
  - 导致后续无法增加节 点实现水品扩展
  - 单个分片的数据量太大，导致数据重新分配耗时
- 分片数设置过大，7.0开始，默认主分片设置成1， 解决了over-sharding的问题
  - 影响搜索结果的相关性打分， 影响统计结果的准确性
  - 单个节点上过多的分片，会导致资源浪费，同时也会影响性能;

## 集群状态

- Green 主分片与副本都正常分配
- Yellow 主分片全部正常分配，有副本分片 未能正常分配
- Red 有主分片未能分配
  - 例如，当服务器的磁盘容量超过85%时去创建了一个新的索引


## 倒排索引


## 分词

- Analyzer 分词

## 搜索

- URI Search

```
GET /movies/_search?q=2O12&df=title&sort=year:desc&from=O&size=1O&timeout=1s
{
"profile" : true
}
```
 
- q指定查询语句，使用Query String Syntax
- df默认字段，不指定时，会对所有字段进行查询
- Sort排序
- from和size 用于分页
- Profile可以查看查询是如何被执行的


Query String Syntax (1)

- 指定字段vs泛查询

q=title:2012 / q=2012

- Term V.S Phrase
Beautiful Mind 等于 Beautiful OR Mind
"Beautiful Mind" 等于 Beautiful AND Mind. Phrase 查询要求前后顺序一致（并且词中间不能有其他词）

- 分组与引号：

- title:(Beautiful AND Mind)
- title= "Beautiful Mind"

## Index template

Index Template的工作方式

当一个索引被新创建时

- 应用Elasticsearch默认的settings和mappings
- 应用order 数值低的Index Template中的设定
- 应用order高的Index Template中的设定，之前的设定会被覆盖
- 应用创建索引时，用户所指定的Settings 和Mappings,并覆盖之前模版中的设定

## Dyanmic template

 
## 聚合 Aggregation

什么是聚合(Aggregation) 

Elasticsearch除搜索以外，提供的针对ES数据进行统计分析的功能
- 实时性高
- Hadoop (T+1)

通过聚合,我们会得到一个数据的概览，是分析和总结全套的数据，而不是寻找单个文档
- 尖沙咀和香港岛的客房数量
- 不同的价格区间，可预定的经济型酒店和五星级酒店的数量

高性能，只需要一条语句，就可以从Elasticsearch得到分析结果 无需在客户端自己去实现分析逻辑.

集合的分类

- Bucket Aggregation - -些列满足特定条件的文档的集合
- Metric Aggregation-一些数学运算，可以对文档字段进行统计分析
- Pipeline Aggregation -对其他的聚合结果进行二次聚合
- Matrix Aggregration-支持对多个字段的操作并提供一个结果矩阵.
