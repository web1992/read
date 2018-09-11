# List

- [List Implementations(oracle docs)](https://docs.oracle.com/javase/tutorial/collections/implementations/list.html)
- [ArrayList vs LinkedList](https://dzone.com/articles/arraylist-vs-linkedlist-vs)
- [when-to-use-LinkedList-over-arraylist(from stackoverflow)](https://stackoverflow.com/questions/322715/when-to-use-linkedlist-over-arraylist)

- [draw.io source](draw.io/list.xml)

![List](images/list.png)

## ArrayList vs LinkedList

- 实现算法不同， `ArrayList` 使用数组，而`LinkedList`使用链表
- LinkedList is faster in add and remove, but slower in get.

1. `ArrayList`在删除元素的时候，使用了`System.arraycopy`来复制所有的元素，性能当然下降
2. `ArrayList`在`add`元素的时候，存在`扩容`的操作，依然需要`System.arraycopy`所有的元素
3. `get(int index)`操作`LinkedList`需要计算元素的索引才能找到，而`ArrayList`内部是素组，直接值通过下表访问即可，无需额外的计算
