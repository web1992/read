# 第 2 章　 Java 内存区域与内存溢出异常

- 堆
- 程序计数器
- 方法区
- 本地方法区
- 虚拟机栈
- 本地方法栈
- 运行时常量池
- 最大栈深度
- StackOverflowError
- OutOfMemoryError 异常
- 元空间（Metaspace）来代替
- 本地内存（直接内存）
- -Xmx -Xms
- -XX：MaxPermSize
- 内存分配 “指针碰撞”（BumpThePointer）
- 内存分配 “空闲列表”（FreeList）
- 本地线程分配缓冲（ThreadLocalAllocationBuffer，TLAB）

## 方法区

方法区（MethodArea）与 Java 堆一样，是各个线程共享的内存区域，它用于存储已被虚拟机加载的类型信息、常量、静态变量、即时编译器编译后的代码缓存等数据。
虽然《Java 虚拟机规范》中把方法区描述为堆的一个逻辑部分，但是它却有一个别名叫作“非堆”（NonHeap），目的是与 Java 堆区分开来。

## 运行时常量池

运行时常量池（RuntimeConstantPool）是方法区的一部分。Class 文件中除了有类的版本、字段、方法、接口等描述信息外，
还有一项信息是常量池表（ConstantPoolTable），用于存放编译期生成的各种字面量与符号引用，这部分内容将在类加载后存放到方法区的运行时常量池中。

运行时常量池相对于 Class 文件常量池的另外一个重要特征是具备动态性，Java 语言并不要求常量一定只有编译期才能产生，也就是说，
并非预置入 Class 文件中常量池的内容才能进入方法区运行时常量池，运行期间也可以将新的常量放入池中，这种特性被开发人员利用得比较多的便是 String 类的 intern()方法。
