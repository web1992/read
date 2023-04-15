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
- 常量池项与常量池缓存项
- _cp_map 
- cp_cache_map
- 重写字节码指令
- Rewriter::rewrite_invokespecial
- ConstantPoolCache
- ConstantPoolCacheEntry
- invokevirtual
- invokeinterface
- invokespecial
- invokestatic
- 表示字段的 ConstantPoolCacheEntry 的字段信息
- 表示方法的 ConstantPoolCacheEntry 的字段信息
- 例程
- InstanceKlass::link_methods
- 设置`编译`执行的入口地址
- 设置`解释`执行的入口地址
- <clinit>方法
- JavaCalls::call


类的生命周期可以分为5个阶段，分别为加载、连接、初始化、使用和卸载。

![jvm-class-load.drawio.svg](./images/jvm-class-load.drawio.svg)


## 类的连接

类的连接步骤总结如下：

- 1）连接父类和实现的接口，子类在连接之前要保证父类和接口已经连接。
- 2）进行字节码验证。
- 3）重写类。
- 4）连接方法。
- 5）初始化vtable和itable

## ClassState

`ClassState` 链接状态+初始化状态

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
- loaded：表示类已经装载并且已经插入继承体系中，在SystemDictionary::add_to_hierarchy()函数中会更新InstanceKlass的_init_state属性为此状态。
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

## 常量池项与常量池缓存项

对于某些使用常量池索引作为操作数的字节码指令来说，当重写字节码指令后，原常量池索引会更改为指向常量池缓存项的索引。

-  _cp_map是整数类型数组，长度和常量池项的总数相同，因此可以直接将常量池项的索引 作为数组下标来获取常量池缓存项的索引

```c++
//源代码位置：openjdk/hotspot/src/share/vm/interpreter/rewriter.cpp

int add_cp_cache_entry(int cp_index) {
   int cache_index = add_map_entry(cp_index, &_cp_map, &_cp_cache_map);
   return cache_index;
}

int add_map_entry(int cp_index, intArray* cp_map, intStack* cp_cache_map) {
   // cp_cache_map是整数类型的栈
   int cache_index = cp_cache_map->append(cp_index);
   cp_map->at_put(cp_index, cache_index);        // cp_map是整数类型的数组
   return cache_index;
}
```

在以上代码中通过cp_cache_map和cp_map建立了cp_index与cache_index的对应关系。


## 重写字节码指令

有些字节码指令的操作数在Class文件里与运行时不同，因为HotSpot VM在连接类的时候会对部分字节码进行重写，把某些指令的操作数从常量池下标改写为常量池缓存下标。之所以创建常量池缓存，部分原因是这些指令所需要引用的信息无法使用一个常量池项来表示，而需要使用一个更大的数据结构表示常量池项的内容，另外也是为了不破坏原有的常量池信息。

HotSpot VM将Class文件中对常量池项的索引更新为对常量池缓存项的索引，在常量池缓存中能存储更多关于解释运行时的相关信息。

创建常量池缓存
常量池缓存可以辅助HotSpot VM进行字节码的解释执行，常量池缓存可以缓存字段获取和方法调用的相关信息，以便提高解释执行的速度。

## ConstantPoolCacheEntry

表示方法的ConstantPoolCacheEntry的字段信息

![ConstantPoolCacheEntry-method.drawio.svg](./images/ConstantPoolCacheEntry-method.drawio.svg)

图7-7中的_f1与_f2字段根据字节码指令调用的不同，其存储的信息也不同。字节码调用方法的指令主要有以下几个：

- 1）invokevirtual：通过vtable进行方法的分发。

   - _f1：没有使用。
   - _f2：如果调用的是非final的virtual方法，则_f2字段保存的是目标方法在vtable中的索引编号；如果调用的是virtual final方法，则_f2字段直接指向目标方法的Method实例。

- 2）invokeinterface：通过itable进行方法的分发。

   - _f1：该字段指向对应接口的Klass实例。
   - _f2：该字段保存的是方法位于itable的itableMethod方法表中的索引编号。

- 3）invokespecial：调用private和构造方法，不需要分发机制。

   - _f1：该字段指向目标方法的Method实例（用_f1字段可以直接定位Java方法在内存中的具体位置，从而实现方法的调用）。

   - _f2：没有使用。

- 4）invokestatic：调用静态方法，不需要分发机制。

   - _f1：该字段指向目标方法的Method实例（用_f1字段可以直接定位Java方法在内存中的具体位置，从而实现方法的调用）。
   - _f2：没有使用。

在invokevirtual和invokespecial等字节码指令对应的汇编片段中，如果_indices中的invoke code for _f1或invoke code for_f2不是字节码指令的操作码，说明方法还没有连接，需要调用InterpreterRuntime::resolve_invoke()函数连接方法，同时为ConstantPoolCacheEntry中的各属性生成相关的信息。

## 方法的连接

- InstanceKlass::link_methods


调用的Interpreter::entry_for_method()函数非常重要，该函数会根据Java方法类型获取对应的方法执行`例程`（就是一段机器代码，为方法的调用准备栈帧等必要信息）的入口地址。

```c++
//源代码位置：openjdk/hotspot/src/share/vm/interpreter/abstractInterpreter.hpp

static address entry_for_method(methodHandle m) {
     AbstractInterpreter::MethodKind mk = method_kind(m);
     return entry_for_kind(mk);
}

static address entry_for_kind(MethodKind k) {
     return _entry_table[k];
}
```

MethodKind是枚举类型，定义了表示不同方法类型的常量，如普通的非同步方法、普通的同步方法、本地非同步方法和本地同步方法。在调用这些方法时，由于调用约定或栈帧结构不同，因此对应的例程入口也不同。获取方法类型后，通过entry_for_kind()函数直接获取对应的入口地址即可。_entry_table在HotSpot VM启动时就会初始化，其中存储的是不同类型方法的例程入口，直接获取即可。需要说明的是，这些例程入口是解释执行时的入口。


## 解释执行的入口地址

```c++
//源代码位置：openjdk/hotspot/src/share/vm/oops/method.cpp

void set_interpreter_entry(address entry){
     _i2i_entry = entry;
     _from_interpreted_entry = entry;
}
```

通过Method类中的_i2i_entry与_from_interpreted_entry属性来保存解释执行的入口地址。

## 设置编译执行的入口地址

在Method::link_method()函数中调用make_adapters()函数设置编译执行的入口地址，代码如下：

```c++
//源代码位置：openjdk/hotspot/src/share/vm/oops/method.cpp

address Method::make_adapters(methodHandle mh, TRAPS) {
  AdapterHandlerEntry* adapter = AdapterHandlerLibrary::get_adapter(mh);
  ...
  mh->set_adapter_entry(adapter);
  mh->_from_compiled_entry = adapter->get_c2i_entry();
  return adapter->get_c2i_entry();
}
```

获取适配器adapter后将其保存在Method的_adapter属性中。_adapter用来适配从解释执行转换为编译执行或从编译执行转换为解释执行。由于HotSpot VM解释模式的调用约定是用栈来传递参数，而编译模式的调用约定更多的是采用寄存器传递参数，二者不兼容，因而从解释执行中调用已经被编译的方法，或者从编译执行中调用需要解释执行的方法时，都需要在调用时进行适配。

将Method的_from_compiled_entry属性初始化为编译模式转解释模式的Stub例程，这样编译模式就可通过此例程回到解释执行的状态了。

## 类的初始化

调用InstanceKlass::initialize_impl()函数对类进行初始化。在对类进行初始化之前必须保证类已经完成连接

```c++
//源代码位置：openjdk/hotspot/src/share/oops/instanceKlass.cpp

void InstanceKlass::initialize_impl(instanceKlassHandle this_oop, TRAPS) {
  // 类的连接
  this_oop->link_class(CHECK);

  bool wait = false;

  // 步骤1：在初始化之前，通过ObjectLocker加锁，防止多个线程并发初始化
  {
   oop init_lock = this_oop->init_lock();
   ObjectLocker ol(init_lock, THREAD, init_lock != NULL);

   Thread *self = THREAD;

   // 步骤2：如果当前instanceKlassHandle正在初始化且初始化线程不是当前线程，则
   // 执行ol.waitUninterruptibly()函数，等待其他线程初始化完成后通知
   while(
     // 类正在进行初始化（being_initialized状态）
     this_oop->is_being_initialized() &&
     // 执行初始化的线程不是当前线程
     !this_oop->is_reentrant_initialization(self)
   ){
       wait = true;
       ol.waitUninterruptibly(CHECK);
   }

   // 步骤3：当前类正在被当前线程初始化。例如，如果X类有静态变量指向new Y类实例，
   // Y类中又有静态变量指向new X类实例，这样外部在调用X时需要初始化X类，初始化过
   // 程中又要触发Y类的初始化，而Y类初始化又再次触发X类的初始化
   if (
      // 类正在进行初始化（being_initialized状态）
      this_oop->is_being_initialized() &&
      // 执行初始化的线程就是当前线程
      this_oop->is_reentrant_initialization(self)
   ){
      return;
   }

   // 步骤4：类已经初始化完成（fully_initialized状态）
   if (this_oop->is_initialized()) {
      return;
   }

   // 步骤5：类的初始化出错（initialization_error状态），抛出NoClassDef-
   // FoundError异常
   if (this_oop->is_in_error_state()) {
     ResourceMark rm(THREAD);
     const char*  desc = "Could not initialize class ";
     const char*  className = this_oop->external_name();
     size_t       msglen = strlen(desc) + strlen(className) + 1;
     char*        message = NEW_RESOURCE_ARRAY(char, msglen);
     if (NULL == message) {
        // 内存溢出，无法创建详细的异常信息
        THROW_MSG(vmSymbols::java_lang_NoClassDefFoundError(), className);
     } else {
        jio_snprintf(message, msglen, "%s%s", desc, className);
        THROW_MSG(vmSymbols::java_lang_NoClassDefFoundError(), message);
     }
   }

   // 步骤6：设置类的初始化状态为being_initialized，设置初始化的线程为当前线程
   this_oop->set_init_state(being_initialized);
   this_oop->set_init_thread(self);
  }

  // 步骤7：如果当前初始化的不是接口和父类不为空并且父类未初始化，则初始化其父类
  Klass* super_klass = this_oop->super();
  if (
     super_klass != NULL &&
     !this_oop->is_interface() &&
     // 判断super_klass的状态是否为fully_initialized，如果是，则should_be_
     // initialized()方法将返回true
     super_klass->should_be_initialized()
  ){
   super_klass->initialize(THREAD);
   ...
  }

  if (this_oop->has_default_methods()) {
   // 步骤7.5: 初始化有默认方法的接口
   for (int i = 0; i < this_oop->local_interfaces()->length(); ++i) {
     Klass*         iface = this_oop->local_interfaces()->at(i);
     InstanceKlass*  ik = InstanceKlass::cast(iface);
     if (ik->has_default_methods() && ik->should_be_initialized()) {
        ik->initialize(THREAD);
        ...
     }
   }
  }

  // 步骤8：执行类或接口的初始化方法<clinit>
  {
   this_oop->call_class_initializer(THREAD); // 调用类或接口的<clinit>方法
  }

  // 步骤9：如果初始化过程没有异常，说明已经完成了初始化。设置类的状态为full_
  // initialized，并通知其他线程初始化已经完成
  if (!HAS_PENDING_EXCEPTION) {
   this_oop->set_initialization_state_and_notify(fully_initialized, CHECK);
  } else {
   // 步骤10和11：如果初始化过程发生异常，则通过set_initialization_state_and_
   // notify()方法设置类的状态为initialization_error并通知其他线程，然后抛出错
   // 误或异常
   Handle e(THREAD, PENDING_EXCEPTION);
   CLEAR_PENDING_EXCEPTION;
   {
     EXCEPTION_MARK;
     this_oop->set_initialization_state_and_notify(initialization_error,
THREAD);
     CLEAR_PENDING_EXCEPTION;
   }
   ...
  }
}
```

## Links

- /jdk17u/src/hotspot/share/oops/klassVtable.cpp