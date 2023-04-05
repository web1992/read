# 第7章 类的连接与初始化

- 类的连接
- 类的验证
- 类的重写
- 方法的链接
- 类的初始化 
- ClassState
- classFileParser.cpp
- verifier.cpp
- Finalizer对象


类的生命周期可以分为5个阶段，分别为加载、连接、初始化、使用和卸载。

![jvm-class-load.drawio.svg](./images/jvm-class-load.drawio.svg)


## 类的连接

类的连接步骤总结如下：

-（1）连接父类和实现的接口，子类在连接之前要保证父类和接口已经连接。
-（2）进行字节码验证。
-（3）重写类。
-（4）连接方法。
-（5）初始化vtable和itable

## ClassState

```c++
//源代码位置：openjdk/hotspot/src/share/vm/oops/instanceKlass.hpp
enum ClassState {
   allocated,                    // 已经为InstanceKlass实例分配了内存
   loaded,                       // 类已经加载
   linked,                       // 类已经连接，但还没有初始化
   being_initialized,            // 正在进行类的初始化
   fully_initialized,            // 完成类的初始化
   initialization_error          // 在初始化的过程中出错
};
```


- allocated：已经分配内存，在InstanceKlass的构造函数中通常会将_init_state初始化为这个状态。
-loaded：表示类已经装载并且已经插入继承体系中，在SystemDictionary::add_to_hierarchy()函数中会更新InstanceKlass的_init_state属性为此状态。
- linked：表示已经成功连接/校验，只在InstanceKlass::link_class_impl()方法中更新为这个状态。
- being_initialized、fully_initialized与initialization_error：在类的初始化函数Instance-Klass::initialize_impl()中会用到，分别表示类的初始化过程中的不同状态——正在初始化、已经完成初始化和初始化出错，函数会根据不同的状态执行不同的逻辑。

## 类的验证

类在连接过程中会涉及验证。HotSpot VM会遵守Java虚拟机的规范，对Class文件中包含的信息进行合法性验证，以保证HotSpot VM的安全。从整体上看，大致进行如下4方面的验证。本节详细介绍前三方面的验证，符号引用验证比较简单，不再展开介绍。

- 文件格式验证：包括魔数和版本号等；
- 元数据验证：对程序进行语义分析，如是否有父类，是否继承了不被继承的类，是否实现了父类或者接口中所有要求实现的方法；
- 字节码验证：指令级别的语义验证，如跳转指令不会跳转到方法体以外的代码上；
- 符号引用验证：符号引用转化为直接引用的时候，可以看作对类自身以外的信息进行匹配验证，如通过全限定名是否能找到对应的类等

## 类的重写

InstanceKlass::link_class_impl()函数在调用verify_code()函数完成字节码验证之后会调用rewrite_class()函数重写部分字节码。重写字节码大多是为了在解释执行字节码过程中提高程序运行的效率。

