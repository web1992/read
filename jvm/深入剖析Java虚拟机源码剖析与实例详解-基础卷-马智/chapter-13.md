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