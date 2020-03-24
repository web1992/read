# HashMap

jdk 1.8 `HashMap` 分析

预先了解的知识

|                 |                       |
| --------------- | --------------------- |
| hash 算法       | 使用hash 映射元素     |
| hash 算法的问题 | hash 冲突             |
| 数据结构-树     | 使用树提高查询效率    |
| 数据结构-链表   | 使用链表解决hash 冲突 |

## get

先从 get 方法入手

```java
// get
public V get(Object key) {
    Node<K,V> e;
    return (e = getNode(hash(key), key)) == null ? null : e.value;
}
// hash
// 计算 hash
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
// getNode
final Node<K,V> getNode(int hash, Object key) {
    Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
    // 检查为空和长度
    // HashMap 底层是使用数组来存放元素的
    if ((tab = table) != null && (n = tab.length) > 0 &&
        // tab[(n - 1) & hash]
        // 这里简单的说下这个& 操作
        // 前提 n 是 2的N次幂，如 2的3次方=8，2的4次方=16 (扩容的时候也会保证这个)
        // 这些数的特点是 转化成二进制之后 最高位都是1 ，其他位都是0
        // 如 8 =1000，16 = 10000 (高位为0省略)
        // 而 减去1之后 8-1=7 = 111（二进制）  16-1=15 =1111（二进制）
        // 它们的二进制有效都是1，其他位都是0
        // 而&操作的特点就是 二进制位都是1结果才是1
        // 从而限制了 & 之后的数值永远不大于 (n-1) 的这个值
        // 这样也就保证了数组不会越界,而数组是从0开始的，n-1 也就是数组的最大下标
        // 这样的设计，简称完美！
        (first = tab[(n - 1) & hash]) != null) {// 不为空，说明数组的这个下表位置已经有数据了
        if (first.hash == hash && // always check first node 检查 key 是不是相等
            ((k = first.key) == key || (key != null && key.equals(k))))
            return first;
        if ((e = first.next) != null) {// 找到下一个
            if (first instanceof TreeNode)
                return ((TreeNode<K,V>)first).getTreeNode(hash, key);// 如果是 树，使用树进行查找
            do {// 这里进行链表的遍历,一直到链表的尾部
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    return e;
            } while ((e = e.next) != null);
        }
    }
    return null;
}
```

## put
