# 第二章 信息的表示和处理

- bit 位
- 无符号 unsigned
- 补码 tow's complement
- 有符号
- 浮点数 floating-point
- 溢出 overflow
- 虚拟内存 巨大的数组 virtual memory
- 十六进制 二进制转化 A C F
- A 1010
- C 1100
- F 1111
- 字长 word size
- 虚拟地址是一个字来编码
- 32位和64位的典型值
- int32_t(4字节) int64_t(8字节) 避免不同编译器之间不同的差异 （ISO 99）
- unsigned long
- unsigned long int
- long unsigned
- long unsigned
- 寻址和字节顺序
- 对象的地址是什么，以及在内存中是如何排列这些字节的
- 前一种规则 最低有效字节在最前面的方式，称为小端法(ittle endian)
- 后一种规则 最高有效字节在最前面的方式，称为大端法(big endian)
- 网络传输顺序
- 阅读顺序，编译器的顺序
- C语言，指针和数组
- man ascii
- 二进制编码是不兼容的
- 布尔代数 Boolean algebra
- 位向量 表示有限的集合
- 加法逆元 additive inverse (P72)
- C语言 位移操作 (P76)
- 左移
- 逻辑右移 算术右移
- 整数的表示
- 补码编码 two' s-complement

## sizeof

这些过程使用C语言的运算符sizeof来确定对象使用的字节数。一般来说，表达式sizeof(T)返回存储一个类型为T的对象所需要的字节数。使用sizeof而不是一个固定的值，是向编写在不同机器类型上可移植的代码迈进了一步。

## 位移操作


## 补码

2.2.3补码编码
对于许多应用，我们还希望表示负数值。最常见的有符号数的计算机表示方式就是补码(two' s-complement)形式。
在这个定义中，将字的最高有效位解释为负权(negative weight)。我们用函数B2Tw (Binary to Two' s-complement的缩写，长度为w)来表示