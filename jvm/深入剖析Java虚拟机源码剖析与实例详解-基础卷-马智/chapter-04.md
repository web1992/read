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
- InstanceKlass
- create_mirror
- Java类的静态变量存储在java.lang.Class对象中
- Metaspace::allocate
- SymbolTable::lookup_only

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

对于上面的代码的理解(ChatGTP)：

这段代码是一个 C++ 的函数，用于在内存中进行原始数据的访问和操作。以下是对这两个函数的解释：

obj_at_addr_raw(int which) const: 这个函数接受一个整数参数 which，并返回一个 intptr_t* 类型的指针。它使用 base() 函数获取一个内存位置的指针，然后通过将其偏移 which 字节来获取最终的内存地址。函数将这个内存地址强制转换为 intptr_t* 类型并返回。

base() const: 这个函数返回一个 intptr_t* 类型的指针。它使用 this 指针，this 指针是指向当前对象实例的指针，并将其转换为 char* 类型。然后，它使用指针算术将 sizeof(ConstantPool) 字节添加到 this 指针上，从而在内存中向前跳过 sizeof(ConstantPool) 字节，并将结果的内存地址强制转换为 intptr_t* 类型并返回。

需要注意的是，原始内存操作，如指针类型转换和指针算术，可能不安全且容易出错，因为它们绕过了类型检查，如果不小心使用可能会导致未定义的行为。建议只在绝对必要且充分了解底层内存布局和类型大小的情况下使用这类技术。此外，不同平台或编译器之间的不同对指针类型转换可能存在对齐问题，并且可能不具备可移植性。

## ConstantPool

```c++
class ConstantPool : public Metadata {
  friend class VMStructs;
  friend class JVMCIVMStructs;
  friend class BytecodeInterpreter;  // Directly extracts a klass in the pool for fast instanceof/checkcast
  friend class Universe;             // For null constructor
 private:
  // If you add a new field that points to any metaspace object, you
  // must add this field to ConstantPool::metaspace_pointers_do().
  Array<u1>*           _tags;        // the tag array describing the constant pool's contents
  ConstantPoolCache*   _cache;       // the cache holding interpreter runtime information
  InstanceKlass*       _pool_holder; // the corresponding class
  Array<u2>*           _operands;    // for variable-sized (InvokeDynamic) nodes, usually empty

  // Consider using an array of compressed klass pointers to
  // save space on 64-bit platforms.
  Array<Klass*>*       _resolved_klasses;

  u2              _major_version;        // major version number of class file
  u2              _minor_version;        // minor version number of class file

  // Constant pool index to the utf8 entry of the Generic signature,
  // or 0 if none.
  u2              _generic_signature_index;
  // Constant pool index to the utf8 entry for the name of source file
  // containing this klass, 0 if not specified.
  u2              _source_file_name_index;
  // ...
}
```

## allocate

```c++
//源代码位置：openjdk/hotspot/src/share/vm/oops/constantPool.cpp

ConstantPool* ConstantPool::allocate(ClassLoaderData* loader_data, int length, TRAPS) {
  Array<u1>* tags = MetadataFactory::new_writeable_array<u1>(loader_data,length, 0, CHECK_NULL);

  int size = ConstantPool::size(length);

  return new (loader_data, size, false, MetaspaceObj::ConstantPoolType,THREAD) ConstantPool(tags);
}

// 通过重载new运算符进行内存分配，new运算符的重载定义在MetaspaceObj（ConstantPool间接继承此类）类中
// 源代码位置：openjdk/hotspot/src/share/vm/memory/allocation.cpp

void* MetaspaceObj::operator new(size_t size, 
                                 ClassLoaderData* loader_data,
                                 size_t word_size,
                                 bool read_only,
                                 MetaspaceObj::Type type, TRAPS) throw() {
  // 在元数据区为ConstantPool实例分配内存空间
  return Metaspace::allocate(loader_data, word_size, read_only,type,CHECK_NULL);
}
```

ConstantPool 构造函数

```c++
// 源代码位置：openjdk/hotspot/src/share/vm/oops/constantPool.cpp

ConstantPool::ConstantPool(Array<u1>* tags) {
  set_length(tags->length());
  set_tags(NULL);
  set_reference_map(NULL);
  set_resolved_references(NULL);
  set_pool_holder(NULL);
  set_flags(0);

  set_lock(new Monitor(Monitor::nonleaf + 2, "A constant pool lock"));

  int length = tags->length();
  for (int index = 0; index < length; index++) {
   tags->at_put(index, JVM_CONSTANT_Invalid);
  }
  set_tags(tags);
}
```