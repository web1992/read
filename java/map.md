# map

- [map (oracle doc)](https://docs.oracle.com/javase/tutorial/collections/implementations/map.html)



## 概要

Map 的集合实现可以分三类：

1.  普通的实现 `HashMap` `TreeMap` `LinkedHashMap`
2.  特殊实现 `EnumMap` `WeakHashMap` `IdentityHashMap`
3.  `ConcurrentHashMap` 并发实现

`TreeMap` 可以保证放入`Map`的元素是有序的（key 自然顺序）,`HashMap`不保证顺序，但是性能比`TreeMap`好。

如果你需要好的性能&key 的插入顺序（这是是插入顺序，不是自然顺序），你可以使用 `LinkedHashMap`.此外，LinkedHashMap 还可以实现 key 的访问顺序。

## 问题思考

- 1  为什么 `HashMap` 无法保证顺序？
- 2 `TreeMap` 是如何实现 key 的自然顺序的？
- 3 `LinkedHashMap` 的插入顺序和访问顺序是如果实现的？

## HashMap

## LinkedHashMap

## TreeMap
