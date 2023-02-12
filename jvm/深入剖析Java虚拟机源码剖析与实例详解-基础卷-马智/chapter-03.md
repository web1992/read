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
                    } else {// 只有系统类加载器parent才会为空，才会走到这里
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

