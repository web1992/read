# 第三章 类与对象

> 概要

- OOP-Klass二分模型
- 对象的创建
- 对象的内存布局
- 对象的访问定位
- 类的加载
- 系统字典

> 关键字

- OOP-Klass 模型
- OOP: ordinary object pointer，或OOPS即普通对象指针，用来描述对象实例信息
- Klass: Java 类的C++对等体，用来描述Java类
- oopDesc 继承体系
- mark word
- oopsHierarchy.hpp
- Klass数据结构定义了所有Klass 类型共享的结构和行为:描述类型自身的布局，以及刻画出与其他类间的关系(父类、子类、兄弟类等)
- instanceKlass JVM层表示Java对象
- Java itables
- Java vtables
- OOP-map
- HSDB
- 加载，连接，初始化
- 元数据
- Classfile
- ClassFileParser 类 ParseClassFile()函数
- 运行时常量池
- 静态常量池
- 符号引用
- 符号引用->直接引用
- 解析（常量池解析）
- 解析是链接的核心环节 (P101)
- 字节码重写 `rewriter.cpp` (P104)
- TLABs Thread Local Allocation Buffers
- 系统字典 systemDictionary.hpp
- SA 代理库
- SA知道如何读取运行中Java进程或Java进程的核心文件的二进制数据
- 快速分配
- 慢速分配

## OOP Klass 二分模型

事实上，HotSpot的设计者并没有按照上述思路设计对象表示系统，而是专门设计了一套OOP-Klass二分模型:

- OOP: ordinary object pointer，或OOPS即普通对象指针，用来描述对象实例信息。
- Klass: Java 类的C++对等体，用来描述Java类。

对于OOPS对象来说，主要职能在于表示对象的实例数据，没必要持有任何虚函数;而在描述Java类的Klass对象中含有VTBL (继承自Klass父类Klass_vtbl)， 那么，Klass就能够根据Java对象的实际类型进行C++的分发(dispatch)，这样一来，OOPS对象只需要通过相应的Klass便可以找到所有的虚函数。这就避免了在每个对象中都分配一个C++ VTBL指针。

Klass向JVM提供两个功能:
- 实现语言层面的 Java 类;
- 实现 Java 对象的分发功能。

上述两个功能在一个C++类中皆能实现。前者在基类Klass中已经实现，而后者是由Klass子类(见图3-5)提供虚函数实现。

## OOP框架+对象的访问机制

在Java应用程序运行过程中，每创建一个Java对象，在JVM内部也会相应地创建一个OOP对象来表示Java对象。OOPS类的共同基类型为oopDesc。

```c++
class oopDesc {
  friend class VMStructs;
  friend class JVMCIVMStructs;
 private:
  volatile markWord _mark;
  union _metadata {
    Klass*      _klass;
    narrowKlass _compressed_klass;
  } _metadata;
    
 public:
  // ......
}
```

- [markWord.hpp](https://github.com/openjdk/jdk19/blob/master/src/hotspot/share/oops/markWord.hpp)
- [oop.hpp](https://github.com/openjdk/jdk19/blob/master/src/hotspot/share/oops/oop.hpp)

![hossopt实战-3-3.drawio.svg](./images/hossopt实战-3-3.drawio.svg)

对象的访问机制

![hossopt实战-3-4.drawio.svg](./images/hossopt实战-3-4.drawio.svg)

当Java程序在JVM中运行时，由new创建的Java对象，将会在堆中分配对象实例。对象实例除了实例数据本身外,JVM还会在实例数据前面自动加上一个对象头。Java程序中通过该
对象实例的引用，可以访问到JVM内部表示的该对象，即instanceOop。当需要访问该类时,如程序需要调用对象方法或访问类变量，则可以通过instanceOop持有的类元数据指针定位到
位于方法区中的instanceKlass对象来完成。


## Klass

Klass数据结构定义了所有Klass类型共享的结构和行为:描述类型自身的布局，以及刻画出与其他类间的关系(父类、子类、兄弟类等)。图3-6描述了一个运行时Klass对象的内存布局。

在Klass对象的成员变量中，第一个字段叫做_layout_helper, 它是反映该对象整体布局的综合描述符。以32位x86系统为例，_layout_helper 被压缩成32个比特位存储。由于频繁被访
问，它被安排在紧随Klass_vtbl 的第一个字段。 若Klass既不是instance 也不是array，该字段值为0。

## 常量池

常量池中持有Class文件中引用的所有字符串常量、类名、接口名、字段名、方法名和其他字符信息。当我们仔细观察虚拟机指令时，会发现指令是围绕符号引用设计的，而不是直接引用。换句话说，指令的执行没有依赖与类、接口、实例或数组的运行时信息，而仅仅是引用了常量池表中的符号信息。不久后我们将看到关于符号引用和直接引用这一话题的内容。

## 加载

初始化类加载器，加载，链接

如果仅从文件的视角考察Java程序，那我们所看到的编译结果便是一堆Class文件。显然，将这些孤立文件串联在一起，形成一个整体，才能称之为一个程序。联系Class文件的秘诀在于符号引用。事实上，Class 文件之间正是通过符号引用建立了密切的关系。在程序运行初期，类加载器将用到的各个类或接口加载进来，然后通过动态链接将它们联接在一起。这样，当程序运行时，便可以实现类型的相互引用和方法调用。

符号引用是以字符串的形式存在的。在每个Class文件中，都有一个常量池，用来存放该类中用到的符号引用。当完成加载以后，来自于Class文件的常量池则会在JVM内部关联上一个位于运行时内存中的常量池数据结构，即运行时常量池。运行时常量池有别于Class文件中的静态常量池。

如果仅仅是符号，那么引用将失去实际意义。只有当符号引用被转换成直接引用，才能帮助运行时准确定位内存实体。符号引用转换成直接引用的过程，称为`解析`。因为符号引用来自于常量池，所以这个过程也被称为常量池解析。解析是链接的核心环节。

# 链接

- 验证
- 准备
- 解析

> 验证

- 方法的访问控制;
- 参数和静态类型检查;
- 堆栈是否被滥用;
- 变量是否初始化;
- 变量是否赋予正确类型;
- 异常表项必须引用了合法的指令; 
- 验证局部变量表;
- 逐一验证每个字节码的合法性。

> 准备

在类的准备阶段中，将为类静态变量分配内存空间并准备好初始化类中的静态变量，但不会执行任何字节码(包括对类变量显式的初始化赋值语句)。
Char类型默认为"\u0000'，byte 默认为(byte)0，boolean 默认为0，float 默认为0.0f, double默认为0.0d, long默认为0L。

> 解析

JVM规范并没有强制规定解析过程发生的时间点。根据不同的实现，可能会在主方法执行前一次性完成对所有类型的解析(早解析)，也可能会在符号引用首次被访问时才去解析(晚解析)。HotSpot 采用的是后者。

解析目标主要是将常量池中的以下4类符号引用(用常量池项表示的字符串)转换为`直接引用`，即`运行时实际内存地址`:

- 类
- 接口
- 字段
- 类方法和接口方法

> 字节码重写 rewriter.cpp

具体来说，就是将原先指向常量池项的索引调整为指向相应的常量池缓存项。如清单3-13所示，`重写字节码`是将按Class文件中顺序出现的常量池索引号变成运行时常量池缓存索引。


## 初始化

- JVM遇到下述需要引用类或接口的指令时: new、 getstatic、 putstatic 或invokestatic.
- 初次调用java.lang.invoke.MethodHandle 实例时，返回结果为REF_getStatic 、
- REF_putStatic或REF_invokeStatic 的方法句柄。
- 调用类库中的反射方法时，如Class类或java.lang.reflect包。
- 初始化类的子类时。
- 类被设计用做JVM启动时的初始类。

初始过程中会调用 `<clinit>` 方法

## clinit

上述代码第1行获取了该类的类初始化方法<clinit>,该方法是由Javac编译器自动生成和命名的，<clinit> 是一个不含参数的静态方法，该方法不能通过程序直接编码方式实现，只能由编译器根据类变量的赋值语句或静态语句块自动插入到Class文件中。此外，<clinit>方法没有任何虚拟机字节码指令可以调用，它只能在类型初始化阶段被虚拟机隐式调用。最终，在代码5行，通过JavaCalls模块2执行该类的<clinit>方法。

## Links

- [markWord.hpp](https://github.com/openjdk/jdk19/blob/master/src/hotspot/share/oops/markWord.hpp)
- [rewriter.cpp](https://github.com/openjdk/jdk19/blob/master/src/hotspot/share/interpreter/rewriter.cpp)
- [instanceKlass.cpp](https://github.com/openjdk/jdk19/blob/master/src/hotspot/share/oops/instanceKlass.cpp)