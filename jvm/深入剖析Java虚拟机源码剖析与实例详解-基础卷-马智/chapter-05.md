# 第5章 字段的解析

- classFileParser.cpp
- parse_fields
- FieldAllocationCount
- FieldAllocationType HotSpot VM 中定义的类型
- BasicType Java类型的定义
- baseic_type_to_atype 函数进行类型转换
- HandleArea与ResourceArea
- os.malloc()
- FieldInfo
- 伪共享
- @Contended -XX:-RestrictContended
- -XX:+PrintFieldLayout
- 字节填充
- @Contended注解
- 字段的内存布局
- layout_fields
- allocation_style
- -XX:+/-CompactFields
- OopMapBlock
- 静态字段


## FieldAllocationType

- Oop：引用类型；
- Byte：字节类型；
- Short：短整型；
- Word：双字类型；
- Double：浮点类型

## 字段存储

```c
f1: [access, name index, sig index, initial value index, low_offset,
high_offset]
f2: [access, name index, sig index, initial value index, low_offset,
high_offset]
      ...
fn: [access, name index, sig index, initial value index, low_offset,
high_offset]
    [generic signature index]
    [generic signature index]
    ...
```

field_info

```c
field_info {
   u2             access_flags;
   u2             name_index;
   u2             descriptor_index;
   u2             attributes_count;
   attribute_info attributes[attributes_count];
}
```

其中，access_flags、name_index与descriptor_index对应的就是每个fn中的access、name index与sig index。另外，initial value index用来存储常量值（如果这个变量是一个常量），low_offset与high_offset可以保存该字段在内存中的偏移量。

## 方法内存分配

继承自Arena的HandleArea与ResourceArea使用的内存都是通过os.malloc()函数直接分配的，因此既不会分配在HotSpot VM的堆区，也不会分配在元数据区，而属于本地内存的一部分

## 伪共享

缓存系统中是以缓存行（Cache Line）为单位存储的。缓存行是2的整数幂个连续字节，一般为32～256个字节。最常见的缓存行是64个字节。当多线程修改互相独立的变量时，如果这些变量共享同一个缓存行，就会无意中影响彼此的性能，这就是伪共享（False Sharing），


## 

- 1. 在类上应用@Contended注解
@Contended注解将使整个字段块的两端都被填充。注意，这里使用了128字节的填充数来避免伪共享，这个数是大多数硬件缓存行的2倍。

- 2. 在字段上应用@Contended注解
在字段上应用@Contended注解将导致该字段从连续的字段内存空间中分离出来。

- 3. 在多个字段上应用@Contended注解
被注解的两个字段都被独立地填充。

- 4. 应用@Contended注解进行字段分组

有时需要对字段进行分组，同一组的字段会和其他非同一组的字段有访问冲突，但是和同一组的字段不会有访问冲突。例如，同一个线程的代码同时更新两个字段是很常见的情况，可以同时为两个字段添加@Contended注解，去掉它们之间的空白填充来提高内存空间的使用效率。

## 字段的内存布局

字段的定义顺序和布局顺序是不一样的。我们在写代码的时候不用关心内存对齐问题，如果内存是按照源代码定义顺序进行布局的话，由于CPU读取内存时是按寄存器（64位）大小为单位载入的，如果载入的数据横跨两个64位，要操作该数据的话至少需要两次读取，加上组合移位，会产生效率问题，甚至会引发异常。比如在一些ARM处理器上，如果不按对齐要求访问数据，会触发硬件异常。

在Class文件中，字段的定义是按照代码顺序排列的，HotSpot VM加载后会生成相应的数据结构，包含字段的名称和字段在对象中的偏移值等。重新布局后，只要改变相应的偏移值即可。

## offset_of_static_fields

调用InstanceMirrorKlass::offset_of_static_fields()函数获取_offset_of_static_fields属性的值，这个属性在2.1.3节中介绍过，表示在java.lang.Class对象中存储静态字段的偏移量。静态字段紧挨着存储在java.lang.Class对象本身占用的内存空间之后。

在计算next_static_double_offset时，因为首先布局的是oop，内存很可能不是按8字节对齐，所以需要调用align_size_up()函数对内存进行8字节对齐。后面就不需要对齐了，因为一定是自然对齐，如果是8字节对齐则肯定也是4字节对齐的，如果是4字节对齐则肯定也是2字节对齐的。

按照oop、double、word、short和byte的顺序计算各个静态字段的偏移量，next_static_xxx_offset指向的就是第一个xxx类型的静态变量在oop实例（表示java.lang.Class对象）中的偏移量。可以看到，在fac中统计各个类型字段的数量就是为了方便在这里计算偏移量。

因为非静态字段存储在instanceOopDesc实例中，并且父类字段存储在前，所以nonstatic_fields_start变量表示的就是当前类定义的实例字段所要存储的起始偏移量位置。

## allocation_style

在HotSpot VM中，对象布局有以下3种模式：

- allocation_style=0：字段排列顺序为oop、long/double、int、short/char、byte，最后是填充字段，以满足对齐要求；
- allocation_style=1：字段排列顺序为long/double、int、short/char、byte、oop，最后是填充字段，以满足对齐要求；
- allocation_style=2：HotSpot VM在布局时会尽量使父类oop和子类oop挨在一起

