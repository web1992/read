# 第6章 方法的解析

- Method ConstMethod
- klassVtable
- klassItable
- vtable
- itable
- _vtable_index
- Code_attribute
- parse_method
- itable :先找到方法表的位置，再找到 Method
- ConstantPoolCacheEntry _f2 常量池缓存
- vtableEntry
- itableMethodEntry
- vtableEntry,itableMethodEntry 是对Method的一个封装
- 函数编号 方法分派
- visit_all_interfaces


## Method

```c++
//源代码位置：openjdk/hotspot/src/share/vm/oops/method.hpp

class Method : public Metadata {
 friend class VMStructs;
 private:
  ConstMethod*      _constMethod;

  MethodData*       _method_data;
  MethodCounters*   _method_counters;
  AccessFlags       _access_flags;
  int              _vtable_index;

  u2              _method_size;
  u1              _intrinsic_id;

  // 以下5个属性对于Java方法的解释执行和编译执行非常重要
  address _i2i_entry;
  AdapterHandlerEntry*   _adapter;
  volatile address _from_compiled_entry;
  nmethod* volatile  _code;
  volatile address  _from_interpreted_entry;
  ...
}

```

Method类中定义的最后5个属性对于方法的解释执行和编译执行非常重要。

- _i2i_entry：指向字节码解释执行的入口。
- _adapter：指向该Java方法的签名（signature）所对应的i2c2i adapter stub。当需要c2i adapter stub或i2c adapter stub的时候，调用_adapter的get_i2c_entry()或get_c2i_entry()函数获取。
- _from_compiled_entry：_from_compiled_entry的初始值指向c2i adapter stub，也就是以编译模式执行的Java方法在调用需要以解释模式执行的Java方法时，由于调用约定不同，所以需要在转换时进行适配，而_from_compiled_entry指向这个适配的例程入口。一开始Java方法没有被JIT编译，需要在解释模式下执行。当该方法被JIT编译并“安装”完成之后，_from_compiled_entry会指向编译出来的机器码入口，具体说是指向verified entry point。如果要抛弃之前编译好的机器码，那么_from_compiled_entry会恢复为指向c2i adapter stub。
- code：当一个方法被JIT编译后会生成一个nmethod，code指向的是编译后的代码。
- _from_interpreted_entry：_from_interpreted_entry的初始值与_i2i_entry一样，都是指向字节码解释执行的入口。但当该Java方法被JIT编译并“安装”之后，_from_interpreted_entry就会被设置为指向i2c adapter stub。如果因为某些原因需要抛弃之前已经编译并安装好的机器码，则_from_interpreted_entry会恢复为指向_i2i_entry。如果有_code，则通过_from_interpreted_entry转向编译方法，否则通过_i2i_entry转向解释方法。


## parse_method

调用parse_method()函数解析每个Java方法，该函数会返回表示方法的Method实例，但Method实例需要通过methodHandle句柄来操作，因此最终会封装为methodHandle句柄，然后存储到_methods数组中。

```c++
//源代码位置：openjdk/hotspot/src/share/vm/classfile/classFileParser.cpp

Array<Method*>* ClassFileParser::parse_methods(
   bool is_interface,
   AccessFlags* promoted_flags,
   bool* has_final_method,
   bool* has_default_methods,
   TRAPS
) {
  ClassFileStream* cfs = stream();
  u2 length = cfs->get_u2_fast();
  if (length == 0) {
   _methods = Universe::the_empty_method_array();
  } else {
   _methods = MetadataFactory::new_array<Method*>(_loader_data, length,NULL, CHECK_NULL);

   HandleMark hm(THREAD);
   for (int index = 0; index < length; index++) {
     // 调用parse_method()函数解析每个Java方法
     methodHandle method = parse_method(is_interface,promoted_flags,CHECK_NULL);

     if (method->is_final()) {
       // 如果定义了final方法，那么has_final_method变量的值为true
       *has_final_method = true;
     }
     if (is_interface
       && !(*has_default_methods)
       && !method->is_abstract()
       && !method->is_static()
       && !method->is_private()) {
        // 如果定义了默认的方法，则has_default_methods变量的值为true
        *has_default_methods = true;
     }
     // 将方法存入_methods数组中
     _methods->at_put(index, method());
   }
  }
  return _methods;
}
```
## ConstantMethod

![ConstantMethod.drawio.svg](./images/ConstantMethod.drawio.svg)

![Method.drawio.svg](./images/Method.drawio.svg)

## klass-vtable


klassVtable与klassItable类用来实现Java方法的多态，也可以称为动态绑定，是指在应用执行期间通过判断接收对象的实际类型，然后调用对应的方法。C++为了实现多态，在对象中嵌入了虚函数表vtable，通过虚函数表来实现运行期的方法分派，Java也通过类似的虚函数表实现Java方法的动态分发。

```c++
//源代码位置：openjdk/hotspot/src/share/vm/oops/klassVtable.hpp

class klassVtable : public ResourceObj {
  KlassHandle  _klass;
  int         _tableOffset;
  int         _length;
  ...
}
```

属性介绍如下：

- _klass：该vtable所属的Klass，klassVtable操作的是_klass的vtable；
- _tableOffset：vtable在Klass实例内存中的偏移量；
- _length：vtable的长度，即vtableEntry的数量。因为一个vtableEntry实例只包含一个Method*，其大小等于字宽（一个指针的宽度），所以vtable的长度跟vtable以字宽为单位的内存大小相同。

vtable表示由一组变长（前面会有一个字段描述该表的长度）连续的vtableEntry元素构成的数组。其中，每个vtableEntry封装了一个Method实例。

vtable中的一条记录用vtableEntry表示，定义如下：

```c++
//源代码位置：openjdk/hotspot/src/share/vm/oops/klassVtable.hpp

class vtableEntry VALUE_OBJ_CLASS_SPEC {
  ...
 private:
  Method* _method;
  ...
};
```

![klass-vtable.drawio.svg](./images/klass-vtable.drawio.svg)

可以看到，在Klass本身占用的内存大小之后紧接着存储的就是vtable（灰色区域）。通过klassVtable的_tableOffset能够快速定位到存储vtable的首地址，而_length属性也指明了存储vtableEntry的数量。

在类初始化时，HotSpot VM将复制父类的vtable，然后根据自己定义的方法更新vtableEntry实例，或向vtable中添加新的vtableEntry实例。当Java方法重写父类方法时，HotSpot VM将更新vtable中的vtableEntry实例，使其指向覆盖后的实现方法；如果是方法重载或者自身新增的方法，HotSpot VM将创建新的vtableEntry实例并按顺序添加到vtable中。尚未提供实现的Java方法也会放在vtable中，由于没有实现，所以HotSpot VM没有为这个vtableEntry项分发具体的方法。

在7.3.3节中介绍常量池缓存时会介绍`ConstantPoolCacheEntry`。在调用类中的方法时，HotSpot VM通过`ConstantPoolCacheEntry`的_f2成员获取vtable中方法的索引，从而取得Method实例以便执行。常量池缓存中会存储许多方法运行时的相关信息，包括对vtable信息的使用。

> 理解此处的 `ConstantPoolCacheEntry` 常量池缓存中的_f2 索引很重要

## 计算vtable的大小

parseClassFile()函数解析完Class文件后会创建InstanceKlass实例保存Class文件解析出的类元信息，因为vtable和itable是内嵌在Klass实例中的，在创建InstanceKlass时需要知道创建的实例的大小，因此必须要在ClassFileParser::parseClassFile()函数中计算vtable和itable所需要的大小

## klassItable虚函数表

![klcass-itable.drawio.svg](./images/klcass-itable.drawio.svg)


itable表由偏移表itableOffset和方法表itableMethod两个表组成，这两个表的长度是不固定的，即长度不一样。每个偏移表itableOffset保存的是类实现的一个接口Klass和该接口方法表所在的偏移位置；方法表itableMethod保存的是实现的接口方法。在初始化itable时，HotSpot VM将类实现的接口及实现的方法填写在上述两张表中。接口中的非public方法和abstract方法（在vtable中占一个槽位）不放入itable中。

调用接口方法时，HotSpot VM通过ConstantPoolCacheEntry的_f1成员拿到接口的Klass，在itable的偏移表中逐一匹配。如果匹配上则获取Klass的方法表的位置，然后在方法表中通过ConstantPoolCacheEntry的_f2成员找到实现的方法Method。


```c++
//源代码位置：openjdk/hotspot/src/share/vm/oops/klassVtable.hpp

class klassItable : public ResourceObj {
 private:
  instanceKlassHandle  _klass;
  int              _table_offset;
  int              _size_offset_table;
  int              _size_method_table;
  ...
}

// ConstantPoolCacheEntry 常量池缓存

class ConstantPoolCacheEntry {
 private:
  volatile intx     _indices;  // constant pool index & rewrite bytecodes
  Metadata* volatile   _f1;       // entry specific metadata field
  volatile intx        _f2;       // entry specific int/metadata field
  volatile intx     _flags;    // flags
}
```

klassItable类包含4个属性：

- _klass：itable所属的Klass；
- _table_offset：itable在所属Klass中的内存偏移量；
- _size_offset_table：itable中itableOffsetEntry的大小；
- _size_method_table：itable中itableMethodEntry的大小。

在接口表itableOffset中含有的项为itableOffsetEntry，类及属性的定义如下：

```c++
//源代码位置：openjdk/hotspot/src/share/vm/oops/klassVtable.hpp

class itableOffsetEntry VALUE_OBJ_CLASS_SPEC {
 private:
  Klass*   _interface;
  int      _offset;
  ...
}
```

其中包含两个属性：

- _interface：方法所属的接口
- _offset：接口下的第一个方法itableMethodEntry相对于所属Klass的偏移量

```c++
// 源代码位置：openjdk/hotspot/src/share/vm/oops/klassVtable.hpp

class itableMethodEntry VALUE_OBJ_CLASS_SPEC {
 private:
  Method*  _method;
  ...
}
```

增加itable而不用vtable解决所有方法分派问题，是因为一个类可以实现多个接口，而每个接口的函数编号是和其自身相关的，vtable无法解决多个对应接口的函数编号问题。而一个子类只能继承一个父亲，子类只要包含父类vtable，并且和父类的函数包含部分的编号是一致的，因此可以直接使用父类的函数编号找到对应的子类实现函数。
