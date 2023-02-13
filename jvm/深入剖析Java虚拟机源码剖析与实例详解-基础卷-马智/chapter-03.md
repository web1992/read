# 第3章 类的加载

- 引导类加载器/启动类加载器（Bootstrap ClassLoader
- 扩展类加载器（Extension ClassLoader）
- 应用类加载器/系统类加载器（Application ClassLoader）
- ClassLoaderData
- Launcher

类加载器可以装载类，这些类被HotSpot VM装载后都以InstanceKlass实例表示（其实还可能是更具体的InstanceRefKlass、InstanceMirrorKlass和InstanceClassLoaderKlass实例）。主要的类加载器有引导类加载器/启动类加载器（Bootstrap ClassLoader）、扩展类加载器（Extension ClassLoader）、应用类加载器/系统类加载器（Application ClassLoader）。

引导类加载器由ClassLoader类实现，这个ClassLoader类是用C++语言编写的，负责将<JAVA_HOME>/lib目录、-Xbootclasspath选项指定的目录和系统属性sun.boot.class.path指定的目录下的核心类库加载到内存中。

## ClassLoaderData

每个类加载器都对应一个ClassLoaderData实例，通过ClassLoaderData::the_null_class_loader_data()函数获取引导类加载器对应的ClassLoaderData实例

parseClassFile()函数首先解析Class文件中的类、字段和常量池等信息，然后将其转换为C++内部的对等表示形式，如将类元信息存储在InstanceKlass实例中，将常量池信息存储在ConstantPool实例中。parseClassFile()函数解析Class文件的过程会在第4章中介绍。最后调用add_package()函数保存已经解析完成的类，避免重复加载解析。

## 引导类加载器

引导类加载器由ClassLoader类实现，这个ClassLoader类是用C++语言编写的，负责将<JAVA_HOME>/lib目录、-Xbootclasspath选项指定的目录和系统属性sun.boot.class.path指定的目录下的核心类库加载到内存中。

## 扩展类加载器

扩展类加载器由sun.misc.Launcher$ExtClassLoader类实现，负责将<JAVA_HOME >/lib/ext目录或者由系统变量-Djava.ext.dir指定的目录中的类库加载到内存中。

## 应用类加载器/系统类加载器

应用类加载器由sun.misc.Launcher$AppClassLoader类实现，负责将系统环境变量-classpath、-cp和系统属性java.class.path指定的路径下的类库加载到内存中。

在Launcher类的构造方法中实例化应用类加载器AppClassLoader时，会调用getApp-ClassLoader()方法获取应用类加载器，传入的参数是一个扩展类加载器ExtClassLoader对象，这样应用类加载器的父加载器就变成了扩展类加载器（与父加载器并非继承关系）。用户自定义的无参类加载器的父类加载器默认是AppClassLoader类加载器

## Launcher类

在Launcher类的构造方法中创建ExtClassLoader与AppClassLoader对象，而loader变量被初始化为AppClassLoader对象，最终在initSystemClassLoader()函数中调用getClass-Loader()方法返回的就是这个对象。HotSpot VM可以通过_java_system_loader属性获取AppClassLoader对象，通过AppClassLoader对象中的parent属性获取ExtClassLoader对象。

## ClassLoader

```java
protected Class<?> loadClass(String name, boolean resolve)
        throws ClassNotFoundException
    {
        synchronized (getClassLoadingLock(name)) {
            // First, check if the class has already been loaded
            Class<?> c = findLoadedClass(name);
            if (c == null) {
                long t0 = System.nanoTime();
                try {
                    if (parent != null) {
                        c = parent.loadClass(name, false);
                    } else {// 只有引导（Bootstrap）类加载器parent才会为空，才会走到这里
                        c = findBootstrapClassOrNull(name);
                    }
                } catch (ClassNotFoundException e) {
                    // ClassNotFoundException thrown if class not found
                    // from the non-null parent class loader
                }

                if (c == null) {
                    // If still not found, then invoke findClass in order
                    // to find the class.
                    long t1 = System.nanoTime();
                    c = findClass(name);
                    // ...
                }
            }
            if (resolve) {
                resolveClass(c);
            }
            return c;
        }
    }
```

## 类的双亲委派机制

各个类加载器之间并不是继承关系，而是表示工作过程，具体说就是，对于一个加载类的具体请求，首先要委派给自己的父类加载器去加载，只有父类加载器无法完成加载请求时子类加载器才会尝试加载，这就叫“双亲委派”

当父类无法完成加载请求也就是c为null时，当前类加载器会调用findClass()方法尝试自己完成类加载的请求。



## loadClass

> java.lang.ClassLoader#loadClass(java.lang.String, boolean)

Loads the class with the specified binary name. The default implementation of this method searches for classes in the following order:
- Invoke findLoadedClass(String) to check if the class has already been loaded.
- Invoke the loadClass method on the parent class loader. If the parent is null the class loader built-in to thevirtual machine is used, instead.
- Invoke the findClass(String) method to find the class.

## findClass

Finds the class with the specified binary name. This method should be overridden by class loader implementations that follow the delegation model for loading classes, and will be invoked by the loadClass method after checking the parent class loader for the requested class. The default implementation throws a ClassNotFoundException.

## defineClass

## 构造类加载器实例

HotSpot VM在启动的过程中会在<JAVA_HOME>/lib/rt.jar包里的sun.misc.Launcher类中完成扩展类加载器和应用类加载器的实例化，并会调用C++语言编写的ClassLoader类的initialize()函数完成应用类加载器的初始化。

```c++
//源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDictionary.cpp
oop  SystemDictionary::_java_system_loader  =  NULL;
```

> 调用链路：

```
JavaMain()                                  java.c
InitializeJVM()                             java.c
JNI_CreateJavaVM()                          jni.cpp
Threads::create_vm()                        thread.cpp
SystemDictionary::compute_java_system_loader()  systemDictionary.cpp
```

```c++
//源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDictionary.cpp
void SystemDictionary::compute_java_system_loader(TRAPS) {
  KlassHandle  system_klass(THREAD, WK_KLASS(ClassLoader_klass));
  JavaValue    result(T_OBJECT);

  // 调用java.lang.ClassLoader类的getSystemClassLoader()方法
  JavaCalls::call_static(
   &result,             // 调用Java静态方法的返回值，并将其存储在result中
    // 调用的目标类为java.lang.ClassLoader
    KlassHandle(THREAD, WK_KLASS(ClassLoader_klass)),
    // 调用目标类中的目标方法为getSystemClassLoader()

    vmSymbols::getSystemClassLoader_name(),
        vmSymbols::void_classloader_signature(),      // 调用目标方法的方法签名
        CHECK
    );

    // 获取调用getSystemClassLoader()方法的返回值并将其保存到_java_system_loader
    // 属性中
    // 初始化属性为应用类加载器/AppClassLoader
    _java_system_loader = (oop)result.get_jobject();
}
```

```
getSystemClassLoader
    -> initSystemClassLoader
    -> Launcher.getLauncher()
    -> Launcher()
```

```java
// 源代码位置：openjdk/jdk/src/share/classes/sun/misc/Launcher.java
private ClassLoader loader;

public Launcher() {
       // 首先创建扩展类加载器
       ClassLoader extcl;
       try {
          extcl = ExtClassLoader.getExtClassLoader();
       } catch (IOException e) {
          throw new InternalError("Could not create extension class loader", e);
       }

       // 以ExtClassloader为父加载器创建AppClassLoader
       try {
          loader = AppClassLoader.getAppClassLoader(extcl);
       } catch (IOException e) {
          throw new InternalError("Could not create application class loader", e);
       }

       // 设置默认线程上下文加载器为AppClassloader
       Thread.currentThread().setContextClassLoader(loader);
}

public ClassLoader getClassLoader() {
       return loader;
}

```

在Launcher类的构造方法中创建ExtClassLoader与AppClassLoader对象，而loader变量被初始化为AppClassLoader对象，最终在initSystemClassLoader()函数中调用getClassLoader()方法返回的就是这个对象。HotSpot VM可以通过_java_system_loader属性获取AppClassLoader对象，通过AppClassLoader对象中的parent属性获取ExtClassLoader对象。

![jvm-class-loader.drawio.svg](./images/jvm-class-loader.drawio.svg)

需要注意的是，图中的各个类加载器之间并不是继承关系，而是表示工作过程，具体说就是，对于一个加载类的具体请求，首先要委派给自己的父类加载器去加载，只有父类加载器无法完成加载请求时子类加载器才会尝试加载，这就叫“双亲委派”。具体的委派逻辑在java.lang.ClassLoader类的loadClass()方法中实现

先调用findLoadedClass()方法查找此类是否已经被加载了，如果没有，则优先调用父类加载器去加载。除了用C++语言实现的引导类加载器需要通过调用findBootstrapClass-OrNull()方法加载以外，其他用Java语言实现的类加载器都有parent字段（定义在java.lang.ClassLoader类中的字段），可直接调用parent的loadClass()方法委派加载请求。除了引导类加载器之外，其他加载器都继承了java.lang.ClassLoader基类。


当父类无法完成加载请求也就是c为null时，当前类加载器会调用findClass()方法尝试自己完成类加载的请求。

```java
import java.net.URL;
import java.net.URLClassLoader;

public class UserClassLoader extends URLClassLoader {

   public UserClassLoader(URL[] urls) {
       super(urls);
   }

   @Override
   protected Class<?> loadClass(String name, boolean resolve) throws
ClassNotFoundException {
       return super.loadClass(name, resolve);
   }
}
```

UserClassLoader类继承了URLClassLoader类并覆写了loadClass()方法，调用super.loadClass()方法其实就是在调用java.lang.ClassLoader类中实现的loadClass()方法。

在UserClassLoader类的构造函数中，调用super()方法会设置当前类加载器的parent字段值为AppClassLoader对象，因此也会严格遵守双亲委派逻辑。


- findBootstrapClassOrNull()方法用于请求引导类加载器完成类的加载请求，该方法会调用本地函数findBootstrapClass()


```c++
源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDictionary.cpp

// “双亲委派”机制体现，只要涉及类的加载，都会调用这个函数
instanceKlassHandle SystemDictionary::load_instance_class(
Symbol* class_name,
Handle class_loader, TRAPS
) {
  instanceKlassHandle nh = instanceKlassHandle();      // 空的Handle
  if (class_loader.is_null()) {         // 使用引导类加载器加载类

   // 在共享系统字典中搜索预加载到共享空间中的类，默认不使用共享空间，因此查找的结果
   // 为NULL
   instanceKlassHandle k;
   {
     k = load_shared_class(class_name, class_loader, THREAD);
   }

   if (k.is_null()) {
     // 使用引导类加载器进行类加载
     k = ClassLoader::load_classfile(class_name, CHECK_(nh));
   }
   // 调用SystemDictionary::find_or_define_instance_class->SystemDictionary::
   // update_dictionary -> Dictionary::add_klass()将生成的Klass实例保存起来
   // Dictionary的底层是Hash表数据结构，使用开链法解决Hash冲突
   if (!k.is_null()) {
     // 支持并行加载，也就是允许同一个类加载器同时加载多个类
     k = find_or_define_instance_class(class_name, class_loader, k, CHECK_(nh));
   }
   return k;
  }
  // 使用指定的类加载器加载，最终会调用java.lang.ClassLoader类中的loadClass()
  // 方法执行类加载
else {

   JavaThread* jt = (JavaThread*) THREAD;

   Handle s = java_lang_String::create_from_symbol(class_name, CHECK_(nh));

   3.1　类加载器
类加载器可以装载类，这些类被HotSpot VM装载后都以InstanceKlass实例表示（其实还可能是更具体的InstanceRefKlass、InstanceMirrorKlass和InstanceClassLoaderKlass实例）。主要的类加载器有引导类加载器/启动类加载器（Bootstrap ClassLoader）、扩展类加载器（Extension ClassLoader）、应用类加载器/系统类加载器（Application ClassLoader）。

3.1.1　引导类加载器/启动类加载器
引导类加载器由ClassLoader类实现，这个ClassLoader类是用C++语言编写的，负责将<JAVA_HOME>/lib目录、-Xbootclasspath选项指定的目录和系统属性sun.boot.class.path指定的目录下的核心类库加载到内存中。

用C++语言定义的类加载器及其重要的函数如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/classLoader.hpp

class ClassLoader::AllStatic {
   private:
    ...
    // 加载类
    static instanceKlassHandle load_classfile(Symbol* h_name,TRAPS);
    ...
}
load_classfile()函数可以根据类名加载类，具体代码如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/classLoader.cpp

instanceKlassHandle ClassLoader::load_classfile(Symbol* h_name, TRAPS) {
  // 获取文件名称
  stringStream st;
  st.print_raw(h_name->as_utf8());
  st.print_raw(".class");
  char* name = st.as_string();

  // 根据文件名称查找Class文件
  ClassFileStream* stream = NULL;
  int classpath_index = 0;
  {
   // 从第一个ClassPathEntry开始遍历所有的ClassPathEntry
   ClassPathEntry* e = _first_entry;
   while (e != NULL) {
     stream = e->open_stream(name, CHECK_NULL);
     // 如果找到目标文件，则跳出循环
     if (stream != NULL) {
       break;
     }
     e = e->next();
     ++classpath_index;
   }
  }

  instanceKlassHandle h;
  // 如果找到了目标Class文件，则加载并解析
  if (stream != NULL) {
   ClassFileParser parser(stream);
   ClassLoaderData* loader_data = ClassLoaderData::the_null_class_loader_data();
   Handle protection_domain;
   TempNewSymbol parsed_name = NULL;
   // 加载并解析Class文件，注意此时并未开始连接
   instanceKlassHandle result = parser.parseClassFile(h_name,
                                             loader_data,
                                             protection_domain,
                                             parsed_name,
                                             false,
                                             CHECK_(h));

   // 调用add_package()函数，把当前类的包名加入_package_hash_table中
   if (add_package(name, classpath_index, THREAD)) {
     h = result;
   }
  }

  return h;
}
每个类加载器都对应一个ClassLoaderData实例，通过ClassLoaderData::the_null_class_loader_data()函数获取引导类加载器对应的ClassLoaderData实例。

因为ClassPath有多个，所以通过单链表结构将ClassPathEntry连接起来。同时，在ClassPathEntry类中还声明了一个虚函数open_stream()，这样就可以循环遍历链表上的结构，直到查找到某个类路径下名称为name的Class文件为止，这时open_stream()函数会返回定义此类的Class文件的ClassFileStream实例。

parseClassFile()函数首先解析Class文件中的类、字段和常量池等信息，然后将其转换为C++内部的对等表示形式，如将类元信息存储在InstanceKlass实例中，将常量池信息存储在ConstantPool实例中。parseClassFile()函数解析Class文件的过程会在第4章中介绍。最后调用add_package()函数保存已经解析完成的类，避免重复加载解析。

3.1.2　扩展类加载器
扩展类加载器由sun.misc.Launcher$ExtClassLoader类实现，负责将<JAVA_HOME >/lib/ext目录或者由系统变量-Djava.ext.dir指定的目录中的类库加载到内存中。

用Java语言编写的扩展类加载器的实现代码如下：

源代码位置：openjdk/jdk/src/share/classes/sun/misc/Launcher.java

static class ExtClassLoader extends URLClassLoader {
   // 构造函数
   public ExtClassLoader(File[] dirs) throws IOException {
       // 为parent字段传递的参数为null
       super(getExtURLs(dirs), null, factory);
   }

   public static ExtClassLoader getExtClassLoader() throws IOException {
       final File[] dirs = getExtDirs();   // 获取加载类的加载路径
       ...
       return new ExtClassLoader(dirs);    // 实例化扩展类加载器
       ...
   }

   private static File[] getExtDirs() {
       String s = System.getProperty("java.ext.dirs");
       File[] dirs;
       if (s != null) {
          StringTokenizer st = new StringTokenizer(s, File.pathSeparator);
          int count = st.countTokens();
          dirs = new File[count];
          for (int i = 0; i < count; i++) {
             dirs[i] = new File(st.nextToken());
          }
       } else {
          dirs = new File[0];
       }
       return dirs;
   }
   ...
}
在ExtClassLoader类的构造函数中调用父类的构造函数时，传递的第2个参数的值为null，这个值会赋值给parent字段。当parent字段的值为null时，在java.lang.ClassLoader类中实现的loadClass()方法会调用findBootstrapClassOrNull()方法加载类，最终会调用C++语言实现的ClassLoader类中的相关函数加载类。

3.1.3　应用类加载器/系统类加载器
应用类加载器由sun.misc.Launcher$AppClassLoader类实现，负责将系统环境变量-classpath、-cp和系统属性java.class.path指定的路径下的类库加载到内存中。

用Java语言编写的扩展类加载器的实现代码如下：

源代码位置：openjdk/jdk/src/share/classes/sun/misc/Launcher.java

static class AppClassLoader extends URLClassLoader {
       // 构造函数
       AppClassLoader(URL[] urls, ClassLoader parent) {
          // parent通常是ExtClassLoader对象
          super(urls, parent, factory);
       }

       public static ClassLoader getAppClassLoader(final ClassLoader
extcl) throws IOException {
          final String s = System.getProperty("java.class.path");
          final File[] path = (s == null) ? new File[0] : getClassPath(s);
          ...
          return new AppClassLoader(urls, extcl);
       }

       public Class loadClass(String name, boolean resolve) throws
ClassNotFoundException {
          ...
          return (super.loadClass(name, resolve));
       }

       ...
}
在Launcher类的构造方法中实例化应用类加载器AppClassLoader时，会调用getApp-ClassLoader()方法获取应用类加载器，传入的参数是一个扩展类加载器ExtClassLoader对象，这样应用类加载器的父加载器就变成了扩展类加载器（与父加载器并非继承关系）。用户自定义的无参类加载器的父类加载器默认是AppClassLoader类加载器。

3.1.4　构造类加载器实例
HotSpot VM在启动的过程中会在<JAVA_HOME>/lib/rt.jar包里的sun.misc.Launcher类中完成扩展类加载器和应用类加载器的实例化，并会调用C++语言编写的ClassLoader类的initialize()函数完成应用类加载器的初始化。

HotSpot VM在启动时会初始化一个重要的变量，代码如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDictionary.cpp

oop  SystemDictionary::_java_system_loader  =  NULL;
其中，_java_system_loader属性用于保存应用类加载器实例，HotSpot VM在加载主类时会使用应用类加载器加载主类。_java_system_loader属性用于在compute_java_system_ loader()函数中进行初始化，调用链路如下：

JavaMain()                                  java.c
InitializeJVM()                             java.c
JNI_CreateJavaVM()                          jni.cpp
Threads::create_vm()                        thread.cpp
SystemDictionary::compute_java_system_loader()  systemDictionary.cpp
compute_java_system_loader()函数的实现代码如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDictionary.cpp

void SystemDictionary::compute_java_system_loader(TRAPS) {
  KlassHandle  system_klass(THREAD, WK_KLASS(ClassLoader_klass));
  JavaValue    result(T_OBJECT);

  // 调用java.lang.ClassLoader类的getSystemClassLoader()方法
  JavaCalls::call_static(
   &result,             // 调用Java静态方法的返回值，并将其存储在result中
    // 调用的目标类为java.lang.ClassLoader
    KlassHandle(THREAD, WK_KLASS(ClassLoader_klass)),
    // 调用目标类中的目标方法为getSystemClassLoader()
    vmSymbols::getSystemClassLoader_name(),
    vmSymbols::void_classloader_signature(),      // 调用目标方法的方法签名
    CHECK
   );

  // 获取调用getSystemClassLoader()方法的返回值并将其保存到_java_system_loader
  // 属性中
  // 初始化属性为应用类加载器/AppClassLoader
  _java_system_loader = (oop)result.get_jobject();
}
在上面的代码中，JavaClass::call_static()函数调用了java.lang.ClassLoader类的getSystem-ClassLoader()方法。JavaClass::call_static()函数非常重要，它是HotSpot VM调用Java静态方法的API。

下面看一下getSystemClassLoader()方法的实现代码：

源代码位置：openjdk/jdk/src/share/classes/java/lang/ClassLoader.java

private static ClassLoader scl;
public static ClassLoader getSystemClassLoader() {
       initSystemClassLoader();
       if (scl == null) {
          return null;
       }
       return scl;
}

private static synchronized void initSystemClassLoader() {
       if (!sclSet) {
          // 获取Launcher对象
          sun.misc.Launcher l = sun.misc.Launcher.getLauncher();
          if (l != null) {
             // 获取应用类加载器AppClassLoader对象
             scl = l.getClassLoader();
             ...
          }
          sclSet = true;
       }
}
以上方法及变量定义在java.lang.ClassLoader类中。

在initSystemClassLoader()方法中调用Launcher.getLauncher()方法获取Launcher对象，这个对象已保存在launcher静态变量中。代码如下：

源代码位置：openjdk/jdk/src/share/classes/sum/misc/Launcher.java

private static Launcher launcher = new Launcher();
在定义静态变量时就会初始化Launcher对象。调用的Launcher构造函数如下：

源代码位置：openjdk/jdk/src/share/classes/sun/misc/Launcher.java

private ClassLoader loader;

public Launcher() {
       // 首先创建扩展类加载器
       ClassLoader extcl;
       try {
          extcl = ExtClassLoader.getExtClassLoader();
       } catch (IOException e) {
          throw new InternalError("Could not create extension class loader", e);
       }

       // 以ExtClassloader为父加载器创建AppClassLoader
       try {
          loader = AppClassLoader.getAppClassLoader(extcl);
       } catch (IOException e) {
          throw new InternalError("Could not create application class loader", e);
       }

       // 设置默认线程上下文加载器为AppClassloader
       Thread.currentThread().setContextClassLoader(loader);
}

public ClassLoader getClassLoader() {
       return loader;
}
以上方法及变量都定义在sum.misc.Lanucher类中。

在Launcher类的构造方法中创建ExtClassLoader与AppClassLoader对象，而loader变量被初始化为AppClassLoader对象，最终在initSystemClassLoader()函数中调用getClass-Loader()方法返回的就是这个对象。HotSpot VM可以通过_java_system_loader属性获取AppClassLoader对象，通过AppClassLoader对象中的parent属性获取ExtClassLoader对象。

3.1.5　类的双亲委派机制
前面介绍了3种类加载器，每种类加载器都可以加载指定路径下的类库，它们在具体使用时并不是相互独立的，而是相互配合对类进行加载。另外，开发者还可以编写自定义的类加载器。类加载器的双亲委派模型如图3-1所示。

003-01
图3-1　类加载器的双亲委派模型

需要注意的是，图3-1中的各个类加载器之间并不是继承关系，而是表示工作过程，具体说就是，对于一个加载类的具体请求，首先要委派给自己的父类加载器去加载，只有父类加载器无法完成加载请求时子类加载器才会尝试加载，这就叫“双亲委派”。具体的委派逻辑在java.lang.ClassLoader类的loadClass()方法中实现。loadClass()方法的实现代码如下：

源代码位置：openjdk/jdk/src/share/classes/java/lang/ClassLoader.java

protected Class<?> loadClass(Stringname,boolean resolve) throws ClassNot
FoundException {
      synchronized (getClassLoadingLock(name)) {
         // 首先从HotSpot VM缓存查找该类
         Class c = findLoadedClass(name);
         if (c ==null) {
            try {  // 然后委派给父类加载器进行加载
                if (parent !=null) {
                   c = parent.loadClass(name,false);
                } else {   // 如果父类加载器为null，则委派给启动类加载器加载
                   c = findBootstrapClassOrNull(name);
                }
            } catch (ClassNotFoundException) {
                // 如果父类加载器抛出ClassNotFoundException异常，则表明父类无
                // 法完成加载请求
            }

            if (c ==null) {
                // 当前类加载器尝试自己加载类
                c = findClass(name);
                ...
            }
         }
         ...
         return c;
      }
   }
首先调用findLoadedClass()方法查找此类是否已经被加载了，如果没有，则优先调用父类加载器去加载。除了用C++语言实现的引导类加载器需要通过调用findBootstrapClass-OrNull()方法加载以外，其他用Java语言实现的类加载器都有parent字段（定义在java.lang.ClassLoader类中的字段），可直接调用parent的loadClass()方法委派加载请求。除了引导类加载器之外，其他加载器都继承了java.lang.ClassLoader基类，如实现了扩展类加载器的ExtClassLoader类和实现了应用类加载器的AppClass-Loader类。类加载器的继承关系如图3-2所示。

003-02
图3-2　类加载器的继承关系

当父类无法完成加载请求也就是c为null时，当前类加载器会调用findClass()方法尝试自己完成类加载的请求。

【实例3-1】　编写一个自定义的类加载器，代码如下：

package com.classloading;

import java.net.URL;
import java.net.URLClassLoader;

public class UserClassLoader extends URLClassLoader {

   public UserClassLoader(URL[] urls) {
       super(urls);
   }

   @Override
   protected Class<?> loadClass(String name, boolean resolve) throws
ClassNotFoundException {
       return super.loadClass(name, resolve);
   }
}
UserClassLoader类继承了URLClassLoader类并覆写了loadClass()方法，调用super.loadClass()方法其实就是在调用java.lang.ClassLoader类中实现的loadClass()方法。

在UserClassLoader类的构造函数中，调用super()方法会设置当前类加载器的parent字段值为AppClassLoader对象，因此也会严格遵守双亲委派逻辑。

接着上面的代码继续往下看：

package com.classloading;

public class Student { }
package com.classloading;

import java.net.URL;

public class TestClassLoader {
   public static void main(String[] args) throws Exception {
       URL url[] = new URL[1];
       url[0] = Thread.currentThread().getContextClassLoader().
getResource("");

       UserClassLoader ucl = new UserClassLoader(url);
       Class clazz = ucl.loadClass("com.classloading.Student");

       Object obj = clazz.newInstance();
   }
}
在上面的代码中，通过UserClassLoader类加载器加载Student类，并调用class.new-Instance()方法获取Student对象。

下面详细介绍java.lang.ClassLoader类的loadClass()方法调用的findLoadedClass()、findBootstrapClassOrNull()与findClass()方法的实现过程。

1. findLoadedClass()方法

findLoadedClass()方法调用本地函数findLoadedClass0()判断类是否已经加载。代码如下：

源代码位置：openjdk/jdk/src/share/classes/java/lang/ClassLoader.java

JNIEXPORT jclass JNICALL
Java_java_lang_ClassLoader_findLoadedClass0(JNIEnv *env, jobject loader,
                                    jstring name)
{
   if (name == NULL) {
       return 0;
   } else {
       return JVM_FindLoadedClass(env, loader, name);
   }
}
调用JVM_FindLoadedClass()函数的代码如下：

源代码位置：openjdk/hotspot/src/share/vm/prims/jvm.cpp

JVM_ENTRY(jclass, JVM_FindLoadedClass(JNIEnv *env, jobject loader, jstring name))

  Handle h_name (THREAD, JNIHandles::resolve_non_null(name));
  // 获取类名对应的Handle
  Handle string = java_lang_String::internalize_classname(h_name, CHECK_NULL);

  // 检查类名是否为空
  const char* str   = java_lang_String::as_utf8_string(string());
  if (str == NULL) return NULL;

  // 判断类名是否过长
  const int str_len = (int)strlen(str);
  if (str_len > Symbol::max_length()) {
   return NULL;
  }

  // 创建一个临时的Symbol实例
  TempNewSymbol klass_name = SymbolTable::new_symbol(str, str_len, CHECK_NULL);

  // 获取类加载器对应的Handle
  Handle h_loader(THREAD, JNIHandles::resolve(loader));

  // 查找目标类是否存在
  Klass* k = SystemDictionary::find_instance_or_array_klass(klass_name,h_loader,Handle(),CHECK_NULL);

  // 将Klass实例转换成java.lang.Class对象
  return (k == NULL) ? NULL :  (jclass) JNIHandles::make_local(env, k->
java_mirror());
JVM_END
JVM_ENTRY是宏定义，用于处理JNI函数调用的预处理，如获取当前线程的Java-Thread指针。因为垃圾回收等原因，JNI函数不能直接访问Klass和oop实例，只能借助jobject和jclass等来访问，所以会调用JNIHandles::resolve_non_null()、JNIHandles::resolve()与JNIHandles::mark_local()等函数进行转换。

调用SystemDictionary::find_instance_or_array_klass()函数的代码如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDicitonary.cpp

// 查找InstanceKlass或ArrayKlass实例，不进行任何类加载操作
Klass* SystemDictionary::find_instance_or_array_klass(
  Symbol*   class_name,
  Handle    class_loader,
  Handle    protection_domain,
  TRAPS
){
  Klass* k = NULL;

  if (FieldType::is_array(class_name)) {       // 数组的查找逻辑
FieldArrayInfo fd;
// 获取数组的元素类型
   BasicType t = FieldType::get_array_info(class_name, fd, CHECK_(NULL));
   if (t != T_OBJECT) {                        // 元素类型为Java基本类型
       k = Universe::typeArrayKlassObj(t);
   } else {                                    // 元素类型为Java对象
       Symbol* sb = fd.object_key();
       k = SystemDictionary::find(sb, class_loader, protection_domain, THREAD);
   }
   if (k != NULL) {
       // class_name表示的可能是多维数组，因此需要根据维度创建ObjArrayKlass实例
       k = k->array_klass_or_null(fd.dimension());
   }
  } else {                                     // 类的查找逻辑
     k = find(class_name, class_loader, protection_domain, THREAD);
  }
  return k;
}
上面代码中的find_instance_or_array_klass()函数包含对数组和类的查询逻辑，并不涉及类的加载。如果是数组，首先要找到数组的元素类型t，如果是基本类型，则调用Universe::typeArrayKlassObj()函数找到TypeArrayKlass实例，如果基本元素的类型是对象，则调用SystemDictionary::find()函数从字典中查找InstanceKlass实例，所有已加载的InstanceKlass实例都会存储到字典中。

调用SystemDictionary::find()函数查找实例，代码如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDicitonary.cpp

Klass* SystemDictionary::find(Symbol* class_name,
                         Handle class_loader,
                         Handle protection_domain,
                         TRAPS) {
  ...
  class_loader = Handle(THREAD, java_lang_ClassLoader::non_reflection_
class_loader(class_loader()));
  ClassLoaderData* loader_data = ClassLoaderData::class_loader_data_or_
null(class_loader());
  ...
  unsigned int d_hash = dictionary()-7gt;compute_hash(class_name, loader_
data);
  int d_index = dictionary()->hash_to_index(d_hash);

  {
   ...
   return dictionary()->find(d_index, d_hash, class_name, loader_data,
protection_domain, THREAD);
  }
}
HotSpot VM会将已经加载的类存储在Dictionary中，为了加快查找速度，采用了Hash存储方式。只有类加载器和类才能确定唯一的表示Java类的Klass实例，因此在计算d_hash时必须传入class_name和loader_data这两个参数。计算出具体索引d_index后，就可以调用Dictionary类的find()函数进行查找。调用Dictionary::find()函数的代码如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDicitonary.cpp

Klass* Dictionary::find(int index, unsigned int hash, Symbol* name,
                     ClassLoaderData* loader_data, Handle protection_
domain, TRAPS) {
  // 根据类名和类加载器计算对应的Klass实例在字典里存储的key
  DictionaryEntry* entry = get_entry(index, hash, name, loader_data);
  if (entry != NULL && entry->is_valid_protection_domain(protection_domain)) {
   return entry->klass();
  } else {
   return NULL;
  }
}
调用get_entry()函数从Hash表中查找Klass实例，如果找到并且验证是合法的，则返回Klass实例，否则返回NULL。

findLoadedClass()方法的执行流程如图3-3所示。

003-03
图3-3　findLoadedClass()方法的执行流程

2. findBootstrapClassOrNull()方法

findBootstrapClassOrNull()方法用于请求引导类加载器完成类的加载请求，该方法会调用本地函数findBootstrapClass()。代码如下：

源代码位置：openjdk/jdk/src/share/classes/java/lang/ClassLoader.java

private Class<?> findBootstrapClassOrNull(String name){
   return findBootstrapClass(name);
}

private native Class<?> findBootstrapClass(String name);
调用findBootstrapClass()函数的代码如下：

源代码位置：openjdk/jdk/src/share/native/java/lang/ClassLoader.c

JNIEXPORT jclass JNICALL Java_java_lang_ClassLoader_findBootstrapClass(
  JNIEnv     *env,
  jobject    loader,
  jstring    classname
){
   char *clname;
   jclass cls = 0;
   char buf[128];

   if (classname == NULL) {
       return 0;
   }

   clname = getUTF(env, classname, buf, sizeof(buf));
   ...
   cls = JVM_FindClassFromBootLoader(env, clname);
   ...
   return cls;
}
调用JVM_FindClassFromBootLoader()函数可以查找启动类加载器加载的类，如果没有查到，该函数会返回NULL。代码如下：

源代码位置：openjdk/hotspot/src/share/vm/prims/jvm.cpp

JVM_ENTRY(jclass, JVM_FindClassFromBootLoader(JNIEnv* env,const char* name))

  // 检查类名是否合法
  if (name == NULL || (int)strlen(name) > Symbol::max_length()) {
   return NULL;
  }

  TempNewSymbol h_name = SymbolTable::new_symbol(name, CHECK_NULL);
  // 调用SystemDictionary.resolve_or_null()函数解析目标类，如果未找到，返回null
  Klass* k = SystemDictionary::resolve_or_null(h_name, CHECK_NULL);
  if (k == NULL) {
   return NULL;
  }
  // 将Klass实例转换成java.lang.Class对象
  return (jclass) JNIHandles::make_local(env, k->java_mirror());
JVM_END
调用SystemDictionary::resolve_or_null()函数可以对类进行查找。代码如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDicitonary.cpp

Klass* SystemDictionary::resolve_or_null(Symbol* class_name, TRAPS) {
  return resolve_or_null(class_name, Handle(), Handle(), THREAD);
}

Klass* SystemDictionary::resolve_or_null(Symbol* class_name, Handle
class_loader,
                                    Handle protection_domain, TRAPS) {
  // 数组，通过签名的格式来判断
  if (FieldType::is_array(class_name)) {
   return resolve_array_class_or_null(class_name, class_loader, protection_
domain, CHECK_NULL);
  }
  // 普通类，通过签名的格式来判断
  else if (FieldType::is_obj(class_name)) {
   // 去掉签名中的开头字符L和结束字符;
   TempNewSymbol name = SymbolTable::new_symbol(class_name->as_C_string()
 + 1,
                                         class_name->utf8_length() - 2,
CHECK_NULL);
   return resolve_instance_class_or_null(name, class_loader, protection_
domain, CHECK_NULL);
  } else {
   return resolve_instance_class_or_null(class_name, class_loader,
protection_domain, CHECK_NULL);
  }
}
调用resolve_array_class_or_null()函数查找数组时，如果数组元素的类型为对象类型，则同样会调用resolve_instance_class_or_null()函数查找类对应的Klass实例。代码如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDicitonary.cpp

Klass* SystemDictionary::resolve_array_class_or_null(
  Symbol*   class_name,
  Handle    class_loader,
  Handle    protection_domain,
  TRAPS
){
  Klass*         k = NULL;
  FieldArrayInfo  fd;
  // 获取数组元素的类型
  BasicType t = FieldType::get_array_info(class_name, fd, CHECK_NULL);
  if (t == T_OBJECT) {                     // 数组元素的类型为对象
   Symbol* sb = fd.object_key();
   k = SystemDictionary::resolve_instance_class_or_null(sb,class_loader,
protection_domain,CHECK_NULL);
   if (k != NULL) {
      k = k->array_klass(fd.dimension(), CHECK_NULL);
   }
  } else {                                 // 数组元素的类型为Java基本类型
   k = Universe::typeArrayKlassObj(t);
   int x = fd.dimension();
   TypeArrayKlass* tak = TypeArrayKlass::cast(k);
   k = tak->array_klass(x, CHECK_NULL);
  }
  return k;
}
对元素类型为对象类型和元素类型为基本类型的一维数组的Klass实例进行查找。查找基本类型的一维数组和find_instance_or_array_klass()函数的实现方法类似。下面调用resolve_instance_class_or_null()函数查找对象类型，代码如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDictionary.cpp

Klass* SystemDictionary::resolve_instance_class_or_null(
  Symbol*   name,
  Handle    class_loader,
  Handle    protection_domain,
  TRAPS
){
  // 在变量SystemDictionary::_dictionary中查找是否已经加载类，如果加载了就直接返回
  Dictionary* dic = dictionary();
  // 通过类名和类加载器计算Hash值
  unsigned int d_hash = dic->compute_hash(name, loader_data);
  // 计算在Hash表中的索引位置
  int d_index = dic->hash_to_index(d_hash);
  // 根据hash和index 查找对应的Klass实例
  Klass* probe = dic->find(d_index, d_hash, name, loader_data,protection_
domain, THREAD);
  if (probe != NULL){
      return probe;             // 如果在字典中找到，就直接返回
  }
  ...
  // 在字典中没有找到时，需要对类进行加载
  if (!class_has_been_loaded) {
     k = load_instance_class(name, class_loader, THREAD);
     ...
  }
  ...
}
如果类还没有加载，那么当前的函数还需要负责加载类。在实现的过程中考虑的因素比较多，比如解决并行加载、触发父类的加载和域权限的验证等，不过这些都不是要讨论的重点。当类没有加载时，调用load_instance_class()函数进行加载，代码如下：

源代码位置：openjdk/hotspot/src/share/vm/classfile/systemDictionary.cpp

// “双亲委派”机制体现，只要涉及类的加载，都会调用这个函数
instanceKlassHandle SystemDictionary::load_instance_class(
Symbol* class_name,
Handle class_loader, TRAPS
) {
  instanceKlassHandle nh = instanceKlassHandle();      // 空的Handle
  if (class_loader.is_null()) {         // 使用引导类加载器加载类

   // 在共享系统字典中搜索预加载到共享空间中的类，默认不使用共享空间，因此查找的结果
   // 为NULL
   instanceKlassHandle k;
   {
     k = load_shared_class(class_name, class_loader, THREAD);
   }

   if (k.is_null()) {
     // 使用引导类加载器进行类加载
     k = ClassLoader::load_classfile(class_name, CHECK_(nh));
   }
   // 调用SystemDictionary::find_or_define_instance_class->SystemDictionary::
   // update_dictionary -> Dictionary::add_klass()将生成的Klass实例保存起来
   // Dictionary的底层是Hash表数据结构，使用开链法解决Hash冲突
   if (!k.is_null()) {
     // 支持并行加载，也就是允许同一个类加载器同时加载多个类
     k = find_or_define_instance_class(class_name, class_loader, k, CHECK_(nh));
   }
   return k;
  }
  // 使用指定的类加载器加载，最终会调用java.lang.ClassLoader类中的loadClass()
  // 方法执行类加载
else {

   JavaThread* jt = (JavaThread*) THREAD;

   Handle s = java_lang_String::create_from_symbol(class_name, CHECK_(nh));
   Handle string = java_lang_String::externalize_classname(s, CHECK_(nh));

   JavaValue result(T_OBJECT);

   KlassHandle spec_klass (THREAD, SystemDictionary::ClassLoader_klass());
   // 调用java.lang.ClassLoader对象中的loadClass()方法进行类加载
   JavaCalls::call_virtual(&result,
                         class_loader,
                         spec_klass,
                         vmSymbols::loadClass_name(),
                         vmSymbols::string_class_signature(),
                         string,
                         CHECK_(nh));

   // 获取调用loadClass()方法返回的java.lang.Class对象
   oop obj = (oop) result.get_jobject();

   // 调用loadClass()方法加载的必须是对象类型
   if ((obj != NULL) && !(java_lang_Class::is_primitive(obj))) {
     // 获取java.lang.Class对象表示的Java类，也就是获取表示Java类的instance
     // Klass实例
     instanceKlassHandle k = instanceKlassHandle(THREAD, java_lang_Class::as_Klass(obj));

     if (class_name == k->name()) {
       return k;
     }
   }
   // Class文件不存在或名称错误，返回空的Handle实例
   return nh;
  }
}
```

当class_loader为NULL时，表示使用启动类加载器加载类，调用ClassLoader::load_classfile()函数加载类；当class_loader不为NULL时，会调用java.lang.ClassLoader类中的loadClass()方法加载。这种判断逻辑也是“双亲委派”机制的体现。
