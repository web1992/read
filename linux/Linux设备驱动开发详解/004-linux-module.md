# 第4章 Linux内核模块

- P314
- Linux设备驱动开发详解：基于最新的Linux4.0内核 (电子与嵌入式系统设计丛书) (宋宝华 著) (Z-Library)

Linux提供了这样的机制，这种机制被称为模块
（Module）。模块具有这样的特点。
·模块本身不被编译入内核映像，从而控制了内
核的大小。
·模块一旦被加载，它就和内核中的其他部分完
全一样。

- printk
- insmod
- lsmod
- /proc/modules
- modprobe
- /lib/modules/<kernel-version>/modules.dep
- modinfo
- 模块加载函数
- 模块卸载函数
- 模块许可证声明
- 模块参数（可选）
- 模块导出符号（可选）
- 模块作者等信息声明
- module_init
- request_module（const char*fmt，…）
- <linux/errno.h>
- .init.text区段
- __initdata
- __init
- __exit
- module_param 模块参数
- module_param_array
- /proc/kallsyms
- EXPORT_SYMBOL
- EXPORT_SYMBOL_GPL
- MODULE_DEVICE_TABLE
- MOD_INC_USE_COUNT、MOD_DEC_USE_COUNT
- try_module_get（&module）和 module_put（&module）
- Linux设备驱动以内核模块的形式存在

##  __exit


我们用__exit来修饰模块卸载函数，可以告诉内
核如果相关的模块被直接编译进内核（即builtin），则cleanup_function（）函数会被省略，直接
不链进最后的镜像。既然模块被内置了，就不可能卸
载它了，卸载函数也就没有存在的必要了。除了函数
以外，只是退出阶段采用的数据也可以用__exitdata
来形容。

## 导出符号

Linux的“/proc/kallsyms”文件对应着内核符号
表，它记录了符号以及符号所在的内存地址。
模块可以使用如下宏导出符号到内核符号表中


## 模块声明与描述

```c
MODULE_AUTHOR(author);
MODULE_DESCRIPTION(description);
MODULE_VERSION(version_string);
MODULE_DEVICE_TABLE(table_info);
MODULE_ALIAS(alternate_name);
```