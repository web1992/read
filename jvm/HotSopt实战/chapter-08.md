# 第八章 指令集

- 取码 ( Instruction Fetch );
- 指令译码 ( Instruction Decode );
- 取操作数 ( Operatand Fetch );
- 执行( Execute );
- 存储结果( Result Store );
- 获取下一条指令 ( Next Instruction ).
- 局部变量、常量池和操作数栈之间的数据传送
- 数据传送指令 P271

## 指令操作

- 数据传送类.
- 运算类:包括算数运算、逻辑运算以及移位运算等。
- 流程控制类:包括控制转移、条件转移、无条件转移以及复合条件转移等。
- 中断、同步、图形处理(硬件)等。
- 指令模板

用于在虚拟机的局部变量和操作数栈之间传送数据的指令主要有3类。

- Load 类指令(数据方向:局部变量→操作数栈),包括iload. iload_<n>、lload.lload <n> .fload、fload_<n>、dload、 dload_<n>、aload、 aload_<n> 等。
- Store 类指令(数据方向:操作数栈→局部变量),包括istore. istore_<n>. lstore. lstore_<n>、fstore、 fstore_<n>、 dstore、 dstore_<n>、 astore、 astore_<n>等。.
- 此外，还有一些指令能够将来自立即数或常量池的数据传送至操作数栈，这类指令包括bipush. sipush. ldc. ldc_w. ldc2_w. aconst_null. iconst_ml. iconst_<i>、 lconst_<1> 、iconst_<i>、fconst_<f>和dconst_<d>等。
