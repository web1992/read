

HashMap 的 Get Put 操作

`HashMap` 底层是由`数组` + `链表` + `树` 等数据结构组合而来的

数组用来存储元素，链表和树则用来优化数组中数据的查询效率 (也就是提高 Get 操作的查询效率)

`HashMap` 最主要的操作就是 `get` 和 `put` 因此从这里入手。

<!--truncate-->

- [Get](#get)
- [Put](#put)

预先了解的知识

| 知道是什么      | 知道怎么解决                        |
| --------------- | ----------------------------------- |
| hash 算法       | 使用hash 映射元素                   |
| hash 算法的问题 | hash 冲突                           |
| 数据结构-树     | 使用树提高查询效率                  |
| 数据结构-链表   | 使用链表解决hash 冲突               |
| 二进制          | 二进制的 & 操作的特点和经典应用场景 |

## Get

先从 `get` 方法入手,可以理解为如何通过 `key` 在数组中查询元素。

从数组中查询一个元素，最简单的方式就是循环遍历，如下：

```java
int[] arr=new int[]{....};
int key =1;// 查询素组中是否有 key =1
for(int i=0;i<arr.lenght;i++){
    if(a == arr[i]){
        // find it ,break
        break;
    }
}
```

这样能实现，但是存在问题，查询数据中如果有100万个数据，那么循环就需要执行100万次，能不能通过某种方式较少循环的次数呢？

当然可以的，`HashMap` 中使用 hash 函数（hash算法）来解决这个问题。hash 函数的特性是，可以把一个字符串(也可以是其他)转换成`一串数字`

而这次`一串数字`可以转换(通过&操作)成数组的下表，然后最快一次就查询到了该元素(这里说是最快，如果发生了hash冲突，就需要多次查询了)

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
        // 这里简单的说下这个 & 操作
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

## Put

```java
// put
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}
// putVal
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
               boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;// 进行初始化
    if ((p = tab[i = (n - 1) & hash]) == null)// 为空，说明i位置上并没存储其他数据
        tab[i] = newNode(hash, key, value, null);// 把key，value 包装成Node，放在i的位置上
    else {
        Node<K,V> e; K k;
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            e = p;// 如果hash相等&Key相等，e=p,下面的 e!=null 会进行处理
        else if (p instanceof TreeNode)// treeNode 的处理
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        else {// 链表的处理
            for (int binCount = 0; ; ++binCount) {
                if ((e = p.next) == null) {// 等于null说明是链表的最后一个元素了
                    p.next = newNode(hash, key, value, null);// 把新的数据包装成Node放在链表的最后
                    // TREEIFY_THRESHOLD=8
                    // 如果链表的长度大于等于8了，那么把链表转换成 TreeNode
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        treeifyBin(tab, hash);
                    break;// 结束循环
                }
                // 如果存在相等的Key, 结束 e!=null 会处理value的赋值
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    break;
                p = e;// break 执行了,p=e 就不会执行了
            }
        }
        if (e != null) { // existing mapping for key
            V oldValue = e.value;// 拿到旧值
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;// 覆盖旧值
            afterNodeAccess(e);// hook Method 这个方法在HashMap 中没作用，在LinkedHashMap 中有使用
            return oldValue;
        }
    }
    // modCount 用来进行并发修改检测的
    // 如果你在遍历元素的时候，其他线程对 hashmap 进行了插入/删除数据
    // 那么此时再继续遍历就不是安全的，抛出 ConcurrentModificationException 异常,而不是一直的错下去
    ++modCount;
    if (++size > threshold)// 数组的长度超过了 threshold 就进行扩容
        resize();// 扩容的目的就是重新计算hash，打散数据，提高查询效率
        // 因为hashmap 的数据越多，产生hash 冲突也就多,get 查询元素的时间复杂度就会从 O(1) 变成 O(n) 了
    afterNodeInsertion(evict);// Hook Method
    return null;
}
```
