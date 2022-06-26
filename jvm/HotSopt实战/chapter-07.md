# 第七章 解释器和即时编译器

- 热点代码
- 即时编译器(Just in Time Compiler， 即JIT编译器)
- 解释模式:可通过-Xint 选项指定，让JVM以解释模式运行Java程序。
- 编译模式:可通过-Xcomp 选项指定，让JVM以编译模式运行Java程序。
- 混合模式:可通过-Xmixed选项指定，让JVM以解释+编译模式运行Java程序。这也是HotSpot的默认模式。
- 机器码(machine code), 本地代码(native code)
- Interpreter 模块
- Code 模块 Code 的存储
- bytecodeindex bci 取码
- 解释器代码 interpreter code
- 宏汇编解释器 InterpreterMacroAssembler 
- -XX:+PrintInterpreter
- 模板表 转发表
- templateTable.cpp

## 解释器

- 解释器( interpreter):解释执行的功能组件。在HotSpot中，实现了两种解释器，一种是虚拟机默认使用的模板解释器( TemplateInterpreter );另一种是C++解释器(CppInterpreter )。
- 代码生成器(code generator): 利用解释器的宏汇编器(缩写为MASM，下文同)向代码缓存空间写入生成的代码。
- InterpreterCodelet:由解释器运行的代码片段。在HotSpot中，所有由代码生成器生成的代码都由一个Codelet来表示。面向解释器的Codelet称为InterpreterCodelet， 由解释器进行维护。利用这些Codelet, JVM可完成在内部空间中存储、定位和执行代码的任务。
- 转发表(dispatch table):为方便快速找到与字节码对应的机器码，模板解释器使用了转发表。它按照字节码的顺序，包含了所有字节码到机器码的关联信息。模板解释器拥有两张转发表，一张是正常模式表，另一张表用来使解释器进入safepoint。 转发表最大256个条目，这也是由单字节表示的字节码最大数量。

在系统启动时，解释器按照预定义的规则，为所有字节码分别创建能够在具体计算机平台上运行的机器码(常称为code,下同)，并存放在特定位置。当运行时环境需要解释字节码时，就到指定位置取出相应的code,直接在机器上运行。然后，解释器再对下一条字节码执行相同的操作。如此循环往复，便完成了整个Java程序的执行任务。


## Links

- [https://github.com/openjdk/jdk7u/blob/master/hotspot/src/share/vm/interpreter/bytecodeInterpreter.cpp](https://github.com/openjdk/jdk7u/blob/master/hotspot/src/share/vm/interpreter/bytecodeInterpreter.cpp)