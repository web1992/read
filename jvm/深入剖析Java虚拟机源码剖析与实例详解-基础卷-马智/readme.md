# 深入剖析Java虚拟机源码剖析与实例详解-基础卷-马智

如果需要阅读HotSopt源码，可以看此书，此书讲解了很多核心的概念，并提供了概述。可以快速入门HotSopt源码。（版本是jdk8）

> 文中的源码都是基于jdk8版本的。

- [第1章 认识HotSpot VM](chapter-01.md)
- [第2章 二分模型](chapter-02.md)
- [第3章 类的加载](chapter-03.md)
- [第4章 类与常量池的解析](chapter-04.md)
- [第5章 字段的解析](chapter-05.md)
- [第6章 方法的解析](chapter-06.md)
- [第7章 类的连接与初始化](chapter-07.md)
- [第8章 运行时数据区](chapter-08.md)
- [第9章 类对象的创建](chapter-09.md)
- [第10章 垃圾回收](chapter-10.md)
- [第11章 Serial垃圾收集器](chapter-11.md)
- [第12章 Serial Old垃圾收集器](chapter-12.md)
- [第13章 Java引用类型](chapter-13.md)


## build hotspot

```sh
bash ./configure --with-debug-level=slowdebug --with-boot-jdk=/Library/Java/JavaVirtualMachines/jdk1.8.0_151.jdk/Contents/Home --enable-debug-symbols --with-xcode-path=/Applications/Xcode-12.5.1.app OBJCOPY=gobjcopy --with-freetype-include=/usr/local/Cellar/freetype/2.13.0_1/include/freetype2  --with-freetype-lib=/usr/local/Cellar/freetype/2.13.0_1/lib
```

```sh
----- Build times -------
Start 2023-04-28 09:37:26
End   2023-04-28 09:47:19
00:00:22 corba
00:00:17 demos
00:01:49 docs
00:03:09 hotspot
00:00:42 images
00:00:12 jaxp
00:00:20 jaxws
00:02:31 jdk
00:00:22 langtools
00:00:09 nashorn
00:09:53 TOTAL
-------------------------
Finished building OpenJDK for target 'all'
```
- [https://www.cnblogs.com/dwtfukgv/p/14727290.html](https://www.cnblogs.com/dwtfukgv/p/14727290.html)