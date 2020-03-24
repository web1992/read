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

## inti and resize

`HashMap` 是延迟初始化的，在 `put` 之后进行初始化操作的

```java
// put -> resize
final Node<K,V>[] resize() {
    Node<K,V>[] oldTab = table;
    // hashmap 无参数初始化的时候 oldCap 和 oldThr 都是0
    // 使用有参数初始化 hashmap 那么 threshold 不为0
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    // threshold -> The next size value at which to resize (capacity * load factor).
    int oldThr = threshold;// 默认的数组大小，默认是0
    int newCap, newThr = 0;
    if (oldCap > 0) {// 扩容走这里
        if (oldCap >= MAXIMUM_CAPACITY) {
            // 超过最大容量，调整 threshold 结束
            threshold = Integer.MAX_VALUE;
            return oldTab;
        }
        else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&// newCap 加倍
                 oldCap >= DEFAULT_INITIAL_CAPACITY)// 如果旧的容量小于16，newThr 加倍
            newThr = oldThr << 1; // double threshold
    }
    else if (oldThr > 0) // initial capacity was placed in threshold 扩容走这里/指定初始容量也走这里
        newCap = oldThr;
    else {               // zero initial threshold signifies using defaults
        // 初始化走这里
        newCap = DEFAULT_INITIAL_CAPACITY;// 默认数组大小是16
        newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);// - 0.75*16=12.0
    }
    if (newThr == 0) {// 指定了初始容量，走这个逻辑，重新计算下一次扩容的容量
        float ft = (float)newCap * loadFactor;
        newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                  (int)ft : Integer.MAX_VALUE);
    }
    threshold = newThr;
    @SuppressWarnings({"rawtypes","unchecked"})
    Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];// 创建新数组
    table = newTab;
    if (oldTab != null) {// 扩容，需要重新计算hash
        for (int j = 0; j < oldCap; ++j) {// 遍历旧数组大小
            Node<K,V> e;
            if ((e = oldTab[j]) != null) {// 找到那些不为 null 的数组元素
                oldTab[j] = null;
                if (e.next == null)// 如果这个位置上的元素上只有一个元素(没有hash冲突)
                    newTab[e.hash & (newCap - 1)] = e;// 直接把这个元素重新进行hash,放到新数组的位置上即可
                else if (e instanceof TreeNode)
                    ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);// 如果是树数据结构
                else { // preserve order 保证顺序
                    Node<K,V> loHead = null, loTail = null;
                    Node<K,V> hiHead = null, hiTail = null;
                    Node<K,V> next;
                    do {
                        next = e.next;
                        if ((e.hash & oldCap) == 0) {
                            if (loTail == null)
                                loHead = e;
                            else
                                loTail.next = e;
                            loTail = e;
                        }
                        else {
                            if (hiTail == null)
                                hiHead = e;
                            else
                                hiTail.next = e;
                            hiTail = e;
                        }
                    } while ((e = next) != null);
                    if (loTail != null) {
                        loTail.next = null;
                        newTab[j] = loHead;
                    }
                    if (hiTail != null) {
                        hiTail.next = null;
                        newTab[j + oldCap] = hiHead;
                    }
                }
            }
        }
    }
    return newTab;
}
```

## put

## Links

- [https://segmentfault.com/a/1190000015812438](https://segmentfault.com/a/1190000015812438)