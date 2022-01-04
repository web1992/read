# struce

```go
type People struct{
    Name String
    Age int
}
```

## 特点

- 结构体的成员如果是大写字母开头的,是可以导出的
- 结构体的成员变量顺序不同，他们就是不同的结构体
- 如果结构的成员都是可比较的，那么这个结构体就是可比较的
- 可比较的结构体可以作为 map 的键类型
- 结构体嵌套和匿名成员


## Links

- [golang struct 值类型](https://blog.csdn.net/love666666shen/article/details/99882528)