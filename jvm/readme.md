# jvm

## blog

- [JVM 的类初始化机制](http://liujiacai.net/blog/2014/07/12/order-of-initialization-in-java/)
- [JVM 参数设置](http://unixboy.iteye.com/blog/174173)
- [StackOverflowError in Java](https://examples.javacodegeeks.com/java-basics/exceptions/java-lang-stackoverflowerror-how-to-solve-stackoverflowerror/)
- [-Xss](http://xmlandmore.blogspot.com/2014/09/jdk-8-thread-stack-size-tuning.html)
- [jstat](https://www.cnblogs.com/yjd_hycf_space/p/7755633.html)
- [metaspace](https://www.cnblogs.com/paddix/p/5309550.html)
- [metaspace](https://plumbr.io/outofmemoryerror/metaspace)
- [gclog](https://blog.csdn.net/renfufei/article/details/49230943)
- [gclog](https://plumbr.io/blog/garbage-collection/understanding-garbage-collection-logs)
- [g1](https://plumbr.io/handbook/garbage-collection-algorithms-implementations/g1)

## 参数设置

```java
-server -Xms1024m -Xmx1024m -Xss256k -XX:PermSize=128m -XX:MaxPermSize=128m -XX:+UseParallelOldGC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/dump -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/opt/dump/heap_trace_payment.txt -XX:NewSize=512m -XX:MaxNewSize=512m
```
