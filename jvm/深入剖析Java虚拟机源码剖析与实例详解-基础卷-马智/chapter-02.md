# 第2章 二分模型

- kclass
- markOop
- oopDesc oop
- markOopDesc 类
- 

## oopDesc

```c++
class oopDesc {
  ...
private:
  volatile markOop _mark;
  union _metadata {
   Klass*      _klass;
   narrowKlass _compressed_klass;
  } _metadata;
  ...
}
```

![oopDesc.drawio.svg](./images/oopDesc.drawio.svg)

Java对象的header信息可以存储在oopDesc类中定义的_mark和_metadata属性中，而Java对象的fields没有在oopDesc类中定义相应的属性来存储，因此只能申请一定的内存空间，然后按一定的布局规则进行存储。对象字段存放在紧跟着oopDesc实例本身占用的内存空间之后，在获取时只能通过偏移来取值。

## markOopDesc类

markOopDesc类的实例可以表示Java对象的头信息Mark Word，包含的信息有哈希码、GC分代年龄、偏向锁标记、线程持有的锁、偏向线程ID和偏向时间戳等

markOopDesc类的实例并不能表示一个具体的Java对象，而是通过一个字的各个位来表示Java对象的头信息。对于32位平台来说，一个字为32位，对于64位平台来说，一个字为64位。

## instanceOopDesc类

> oopDesc 内存布局

![2-11.drawio.svg](./images/oopDesc-layout.drawio.svg)

- 对象头 
 对象头分为两部分，一部分是Mark Word，另一部分是存储指向元数据区对象类型数据的指针_klass或_compressed_klass。它们两个在介绍oopDesc类时详细讲过，这里不再赘述。 

 - 对象字段数据 

 Java对象中的字段数据存储了Java源代码中定义的各种类型的字段内容，具体包括父类继承及子类定义的字段。 
 
 存储顺序受HotSpot VM布局策略命令-XX:FieldsAllocationStyle和字段在Java源代码中定义的顺序的影响，
 默认布局策略的顺序为long/double、int、short/char、boolean、oop（对象指针，32位系统占用4字节，64位系统占用8字节），相同宽度的字段总被分配到一起。 
 如果虚拟机的-XX:+CompactFields参数为true，则子类中较窄的变量可能插入空隙中，以节省使用的内存空间。
 例如，当布局long/double类型的字段时，由于对齐的原因，可能会在header和long/double字段之的空隙中。

- 对齐填充 

对齐填充不是必需的，只起到占位符的作用，没有其他含义。HotSpot VM要求对象所占的内存必须是8字节的整数倍，对象头刚好是8字节的整数倍，
因此填充是对实例数据没有对齐的情况而言的。对象所占的内存如果是以8字节对齐，那么对象在内存中进行线性分配时，对象头的地址就是以8字节对齐的，
这时候就为对象指针压缩提供了条件，可以将地址缩小8倍进行存储


## Handle

对oop直接引用时，如果oop的地址发生变化，那么所有的引用都要更新，图2-14中有3处引用都需要更新；当通过Handle对oop间接引用时，如果oop的地址发生变化，那么只需要更新Handle中保存的对oop的引用即可。

> Handle 类的继承关系

![handle.drawio.svg](./images/handle.drawio.svg)

> 使用 Handle 引用对象

![handle-reference.drawio.svg](./images/handle-reference.drawio.svg)

另外还需要知道，Handle被分配在本地线程的HandleArea中，这样在进行垃圾回收时只需要扫描每个线程的HandleArea即可找出所有Handle，进而找出所有引用的活跃对象。

## HandleArea类与Chunk类之间的关系

![HandleArea.drawio.svg](./images/HandleArea.drawio.svg)

## HandleMark

每一个Java线程都有一个私有的句柄区_handle_area用来存储其运行过程中的句柄信息，这个句柄区会随着Java线程的栈帧而变化。
Java线程每调用一个Java方法就会创建一个对应的HandleMark保存创建的对象句柄，然后等调用返回后释放这些对象句柄，此时释放的仅是调用当前方法创建的句柄，
因此HandleMark只需要恢复到调用方法之前的状态即可。