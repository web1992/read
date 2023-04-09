# 第6章 方法的解析

- Method与ConstMethod类
- klassVtable
- klassItable
- vtable
- itable


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


![klass-vtable.drawio.svg](./images/klass-vtable.drawio.svg)
