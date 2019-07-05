# limit

## limit 优化

- 使用`limit` 进行分页查询的时候，当遇到偏移量（如：limit 50000,10）很大的时候，性能会很差，因为`mysql`会扫描丢弃大量无用的行

```sql
    select film_id,film_desc
    from film inner join(
        select film_id from film  order by title limit 50000,10
    ) as t1 using(film_id);
```

- 使用 limit & offset 进行优化

可以记录上次查询的位置，只查询上次记录位置之后的数据

```sql
select film.film_id,film_desc  from film where film_id> 50 limit 10;
```
