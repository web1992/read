# 第13章 Java引用类型

- Java对象的引用主要包括强引用、软引用、弱引用和虚引用，程序员可以通过代码来决定某些对象的生命周期，同时也有利于JVM进行垃圾回收。
- 强引用（StrongReference）：是平时创建对象和数组时的引用。强引用在任何时候都不会被垃圾收集器回收；
- 软引用（SoftReference）：在系统内存紧张时才会被JVM回收；
- 弱引用（WeakReference）：一旦JVM执行垃圾回收操作，弱引用就会被回收；
- 虚引用（PhantomReference）：主要作为其指向Referent被回收时的一种通知机制；
- 最终引用（FinalReference）：用于收尾机制（finalization）。
- Reference和referent可能处在不同的代中

Reference引用对象有以下几种状态：

- Active：新创建的引用对象的状态为Active。GC检测到其可达性发生变化时会更改其状态。此时分两种情况，如果该引用对象创建时有注册引用队列，则会进入Pending状态，否则会进入Inactive状态。
- Pending：在Pending列表中的元素状态为Pending状态，等待被ReferenceHandler线程消费并加入其注册的引用队列。如果该引用对象未注册引用队列，则永远不会处于这个状态。
- Enqueued：该引用对象创建时有注册引用队列并且当前引用对象在此队列中。当该引用对象从其注册引用队列中移除后状态变为Inactive。如果该引用对象未注册引用队列，则永远不会处于这个状态。
- Inactive：当处于Inactive状态时无须任何处理，因为一旦变成Inactive状态，其状态永远不会再发生改变

## 软引用

Java使用SoftReference表示软引用，软引用表示那些“还有用但是非必须”的对象。对于软引用指向的对象，在HotSpot VM内存紧张时才会回收。

## 弱引用

Java使用WeakReference表示弱引用，弱引用指那些“非必须”的对象，它的强度比软引用更弱一些。被弱引用关联的对象只能生存到下一次垃圾收集发生之前，也就是说，一旦发生GC，弱引用关联的对象一定会被回收，不管当前的内存是否足够。

## 虚引用

Java使用PhantomReference表示虚引用，它是所有引用类型中最弱的一种。一个对象是否关联到虚引用，完全不会影响该对象的生命周期，也无法通过虚引用来获取一个对象的实例。为对象设置一个虚引用的唯一目的是在该对象被垃圾收集器回收的时候能够收到系统通知。

## 最终引用

FinalReference类只有一个子类Finalizer，并且Finalizer由关键字final修饰，因此无法继承扩展。

由于构造函数是私有的，所以只能由HotSpot VM通过调用register()方法将被引用的对象封装为Finalizer对象，但是需要清楚地知道这个被引用的对象及什么时候调用register()方法。

在类加载的过程中，如果当前类重写了finalize()方法，则其对象会被封装为`FinalReference`对象，这样FinalReference对象的referent字段就指向了当前类的对象。需要注意的是，Finalizer对象链会保存全部的只存在FinalizerReference引用且没有执行过finalize()方法的Finalizer对象，防止Finalizer对象在其引用的对象之前被GC回收。在GC过程中如果发现referent对象不可达，则Finalizer对象会添加到queue队列中，所有在queue队列中的对象都会调用finalize()方法。

在HotSpot VM中，在GC进行`可达性分析`的时候，如果当前对象是finalizer类型的对象（重写了finalize()方法的对象）并且本身不可达，则该对象会被加入一个ReferenceQueue类型的队列中。而系统在初始化的过程中会启动一个FinalizerThread类型的守护线程（线程名，Finalizer），该线程会不断消费ReferenceQueue中的对象，并执行其finalize()方法。对象在执行finalize()方法后，只是断开了与Finalizer的关联，并不意味着会立即被回收，要等待下一次GC时才会被回收，而每个对象的finalize()方法只会执行一次，不会重复执行。
