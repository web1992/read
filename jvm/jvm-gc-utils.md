# GC 工具

- jcmd <pid> VM.metaspace 
- jstat -gcutil <pid> 1s
- jstat -gc <pid> 1s
- jps -v
- jinfo <pid>
- java -XX:+PrintFlagsFinal 打印Java的默认参数


## Links

- [jstat 分析GC+内存占用](https://www.cnblogs.com/StarbucksBoy/p/11342188.html)
- [jcmd](https://www.cnblogs.com/webor2006/p/10669472.html)
- [jvm 常用的命令](https://www.cnblogs.com/duanxz/p/6115722.html)