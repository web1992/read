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
- [JVM 指令手册](https://www.cnblogs.com/lsy131479/p/11201241.html)
- [垃圾回收](https://draveness.me/system-design-memory-management/)
- [JVM 总结](https://mp.weixin.qq.com/s/RabFNSMDN7Qv2SBXfYMYNw)

## JNI

- [JNI Interface Functions and Pointers](https://docs.oracle.com/javase/6/docs/technotes/guides/jni/spec/design.html#wp615)
- [https://docs.oracle.com/javase/6/docs/technotes/guides/jni/spec/jniTOC.html](https://docs.oracle.com/javase/6/docs/technotes/guides/jni/spec/jniTOC.html)

## 参数设置

```java
-server -Xms1024m -Xmx1024m -Xss256k -XX:PermSize=128m -XX:MaxPermSize=128m -XX:+UseParallelOldGC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/dump -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/opt/dump/heap_trace_payment.txt -XX:NewSize=512m -XX:MaxNewSize=512m
```


## 内存分析

```sh
ps -mp 41450 -o THREAD,tid,time

printf "%x\n" 41458
# a1f2

jstack 41450 |grep  -A 10 a1f2

```