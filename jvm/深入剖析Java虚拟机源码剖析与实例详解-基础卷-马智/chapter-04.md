# 第4章 类与常量池的解析

- Class文件的结构
- create_mirror
- ClassFileParser类
- ClassFileStream类
- ClassLoaderData
- _transitive_interfaces 实现的所有接口（包括直接和间接实现的接口）
- instanceKlassHandle
- 常量池的解析
- ConstantPool类
- ConstantPool实例
- 而在HotSpot VM中，所有的字符串都用Symbol实例来表示
- CPSlot
- constantTag
- OopMapBlock

Class文件格式采用一种类似于C语言结构体的伪结构来存储数据。常用的数据结构如下：

无符号数：基本数据类型，用u1、u2、u4和u8分别代表1个字节、2个字节、4个字节和8个字节的无符号数，可用来描述数字、索引引用、数量值和UTF-8编码构成的字符串值。
表：多个无符号数或者其他表作为数据项构成的复合数据类型，以`_info`结尾，用于描述有层次关系的复合结构的数据，整个Class文件本质上是一张表。

## 文件结构

```c++
class ClassFileParser VALUE_OBJ_CLASS_SPEC {
 private:
  // 类的主版本号与次版本号
  u2   _major_version;
  u2   _minor_version;
  // 类名称
  Symbol* _class_name;
  // 加载类的类加载器
  ClassLoaderData* _loader_data;

  ...
  // 父类
  instanceKlassHandle _super_klass;
  // 常量池引用
  ConstantPool*    _cp;
  // 类中定义的变量和方法
  Array<u2>*       _fields;
  Array<Method*>*   _methods;
  // 直接实现的接口
  Array<Klass*>*    _local_interfaces;
  // 实现的所有接口（包括直接和间接实现的接口）
  Array<Klass*>*    _transitive_interfaces;
  ...
  // 表示类的InstanceKlass实例，类最终解析的结果会存储到该实例中
  InstanceKlass*    _klass;
  ...
  // Class文件对应的字节流，从字节流中读取信息并解析
  ClassFileStream*  _stream;
  ...
}
```

## ClassFileParser ClassFileStream

每解析一个类，就需要一个 ClassFileParser + ClassFileStream 对象，内部维护了流的读取位置

```c++
//源代码位置：openjdk/hotspot/src/share/vm/classfile/classFileStream.hpp

class ClassFileStream: public ResourceObj {
 private:
  u1*   _buffer_start;          // 指向流的第一个字符位置
  u1*   _buffer_end;            // 指向流的最后一个字符的下一个位置
  u1*   _current;               // 当前读取的字符位置
  ...
}
```

## 解析结果保存

创建表示java.lang.Class对象的oop实例后，将其设置为InstanceKlass实例的_java_mirror属性，同时设置oop实例的偏移位置为_klass_offset处存储的指向InstanceKlass实例的指针


## 解析常量池项
```c++
#3 = Class         #17        // TestClass
...
#17 = Utf8          TestClass
```

在以上代码中，类索引为3，在常量池里找索引为3的类描述符，类描述符中的索引为17，再去找索引为17的字符串，即TestClass。调用obj_at_addr_raw()函数找到的是一个指针，这个指针指向表示TestClass字符串的Symbol实例，也就是在解析常量池项时会将本来存储的索引值为17的位置替换为存储指向Symbol实例的指针。

```c++
//源代码位置：openjdk/hotspot/src/share/vm/oops/constantPool.hpp

intptr_t*   obj_at_addr_raw(int which) const {
   return (intptr_t*) &base()[which];
}
intptr_t*   base() const {
  return (intptr_t*) ( ( (char*) this ) + sizeof(ConstantPool) );
}
```