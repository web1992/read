# Redis 集合

![redis-collection.png](./images/redis-collection.png)

- 聚合统计
- 排序统计
- 二值状态统计
- 基数统计
- Bitmap
- HyperLogLog
- GeoHash 的编码方法

在 Redis 常用的 4 个集合类型中（List、Hash、Set、Sorted Set），List 和 Sorted Set 就属于有序集合。
List 是按照元素进入 List 的顺序进行排序的，而 Sorted Set 可以根据元素的权重来排序。

## HyperLogLog

HyperLogLog 是一种用于统计基数的数据集合类型，它的最大优势就在于，当集合元素数量非常多时，它计算基数所需的空间总是固定的，而且还很小。

## Links

- [GEOSEARCH GEO加强](https://developer.aliyun.com/article/780257)