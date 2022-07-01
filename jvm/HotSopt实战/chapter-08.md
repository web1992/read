# 第八章 指令集

## 概要


- 取码 (Instruction Fetch)
- 指令译码 (Instruction Decode)
- 取操作数 (Operatand Fetch)
- 执行 (Execute)
- 存储结果 (Result Store)
- 获取下一条指令 (Next Instruction)
- 局部变量、常量池和操作数栈之间的数据传送
- 数据传送指令 P271
- 控制转移指令
- 条件转移
- 无条件转移
- 类型转化
- 算术逻辑运算指令
- 方法调用
- invokevirtual
- invokeinterface
- invokespceial
- invokestatic
- invokedynamic
- 返回指令 ireturn,areturn
- itable offset table + method table
- vtable
- 异常
- 栈回溯 stack trace
- athrow
- try-finally

## 指令操作

- 数据传送类.
- 运算类:包括算数运算、逻辑运算以及移位运算等。
- 流程控制类:包括控制转移、条件转移、无条件转移以及复合条件转移等。
- 中断、同步、图形处理(硬件)等。
- 指令模板

用于在虚拟机的局部变量和操作数栈之间传送数据的指令主要有3类。

- Load 类指令(数据方向:局部变量→操作数栈),包括iload. iload_<n>、lload、lload_<n> .fload、fload_<n>、dload、 dload_<n>、aload、 aload_<n> 等。
- Store 类指令(数据方向:操作数栈→局部变量),包括istore. istore_<n>. lstore. lstore_<n>、fstore、 fstore_<n>、 dstore、 dstore_<n>、 astore、 astore_<n>等。.
- 此外，还有一些指令能够将来自立即数或常量池的数据传送至操作数栈，这类指令包括bipush、sipush、 ldc、ldc_w、 ldc2_w、aconst_null、iconst_ml、 iconst_<i>、 lconst_<1> 、iconst_<i>、fconst_<f>和dconst_<d>等。

## Vtable Itable

在Java中，VTABLE用来表示该类自有函数(static、final 函数除外)和父类的虚函数表; itable 用来表示类实现接口的函数列表。
在内存中，VTABLE 和ITABLE位于instanceKlass对象的末尾。

## Itable

而在一个并不支持类多重继承的系统中，设计多层接口继承机制显然要复杂一些。 单独依靠VTABLE机制并不能解决这个问题。在继承关系中，一个类只能继承自一个父类，子类只要从父类那里获得VTABLE,并且与父类共享部分函数的相同顺序，就可以使用父类的函数顺序找到对应子类的实现函数。而一个Java类允许实现多个接口，而每个接口都有自己的函数顺序。单个VTABLE不能解决多个接口的函数顺序问题，因此，虚拟机另外提供了一套ITABLE机制解决这个问题。

ITABLE表由一组偏移表(offset table) 和方法表(method table) 组成，这两组表的元素都是变长的。其中，每个偏移表元素(offset table entry)保存的是类实现的一个接口，以及该接口的方法表所在的偏移位置;方法表元素中保存的是实现的接口方法。方法在方法表中的偏移位置，同样也是利用ConstantPoolCacheEntry的f2成员进行保存的。在初始化ITABLE时，虚拟机将类实现的接口及实现的方法信息填写在上述两张表中。接口中若有abstract以及非public 的方法，则不加入到ITABLE中。当需要调用接口方法时，虚拟机在ITABLE的偏移表中查到对应的接口以及它的方法表位置，然后在方法表中找到实现的接口方法，完成Java接口方法的分发。

## 异常机制

Java通过组合两种机制，保证程序通过上述所有路径都必须进入finally语句块。
- 编译期植入finally语句:将finally中的语句块复制一份插入try语句块字节码后面，保证try执行完毕后立即执行finally语句块代码。

- 异常表: Java 编译器会为finally 语句块生成一个handler，用来捕获try语句块范围内的所有类型异常(异常表项type为any)，当try 语句块中抛出异常时，hanler 捕获到该异常，执行handler的处理程序一finally语句块。


## Links

- [vtable 实现源码](https://zhuanlan.zhihu.com/p/34961967)
