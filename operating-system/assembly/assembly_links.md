# assembly

## 关键字

- 段式管理
- 页式管理
- 局描述符表（Global Descriptor Table, GDT)
- 总的来说，现代的操作系统都是采用段式管理来做基本的权限管理，而对于内存的分配、回收、调度都是依赖页式管理
- 中断描述符表（Interruption Description Table, IDT)
- 中断根据中断来源的不同，又可以细分为 Fault、Trap、Abort 以及普通中断

## Links

- [CPU 总线](https://www.cnblogs.com/yilang/p/11005532.html)
- [8086CPU简介](https://www.cnblogs.com/BoyXiao/archive/2010/11/20/1882716.html)
- [x86汇编基础-Move指令和基本寻址](https://www.jianshu.com/p/fd1cfed8a2d2)