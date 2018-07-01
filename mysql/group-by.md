# group by

## group by 查询优化

- `group by`进行分组查询的时候，无法使用索引的时候，会用到`临时表`  和`文件排序`,这两种情况都是可以优化的
- `group by`结果会自动进行排序，可以使用`order by null`禁止排序
