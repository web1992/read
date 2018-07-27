# Collection

- [Collection](https://liujiacai.net/blog/2015/09/01/java-collection-overview/#disqus_thread)
- [colllection guides (oracle)](https://docs.oracle.com/javase/8/docs/technotes/guides/collections/index.html)

## Collection Implementations

Interface| Hash Table| Resizable Array |Balanced Tree| Linked List |Hash Table + Linked
---------|------------|-----------------|-------------|-------------|--------------------
Set |HashSet||TreeSet| |LinkedHashSet
List||ArrayList||LinkedList
Deque||ArrayDeque||LinkedList
Map|HashMap||TreeMap||LinkedHashMap

All of the new implementations have fail-fast iterators, which detect invalid concurrent modification, and fail quickly and cleanly (rather than behaving erratically).

## Concurrent Collections

### interfaces

- BlockingQueue
- TransferQueue
- BlockingDeque
- ConcurrentMap
- ConcurrentNavigableMap

### implementation

- LinkedBlockingQueue
- ArrayBlockingQueue
- PriorityBlockingQueue
- DelayQueue
- SynchronousQueue
- LinkedBlockingDeque
- LinkedTransferQueue
- CopyOnWriteArrayList
- CopyOnWriteArraySet
- ConcurrentSkipListSet
- ConcurrentHashMap
- ConcurrentSkipListMap