# JVM 配置

## 参数设置

```java
-server
-Xms1024m
-Xmx1024m
-Xss256k
-XX:PermSize=128m
-XX:MaxPermSize=128m
-XX:+UseParallelOldGC
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/opt/dump
-XX:+PrintGCDetails
-XX:+PrintGCDateStamps
-Xloggc:/opt/dump/heap_trace_payment.txt 
-XX:NewSize=512m -XX:MaxNewSize=512m
```
