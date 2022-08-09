# Java agent

- agentmain
- premain
- redefine和retransform


## redefine和retransform

Java agent 还提供了另外两个功能redefine和retransform。这两个功能针对的是已加载的类，并要求用户传入所要redefine或者retransform的类实例。其中，redefine指的是舍弃原本的字节码，并替换成由用户提供的 byte 数组。该功能比较危险，一般用于修复出错了的字节码。retransform则将针对所传入的类，重新调用所有已注册的ClassFileTransformer的transform方法。它的应用场景主要有如下两个。

第一，在执行premain或者agentmain方法前，Java 虚拟机早已加载了不少类，而这些类的加载事件并没有被拦截，因此也没有被注入。使用retransform功能可以注入这些已加载但未注的类。

第二，在定义了多个 Java agent，多个注入的情况下，我们可能需要移除其中的部分注入。当调用Instrumentation.removeTransformer去除某个注入类后，我们可以调用retransform功能，重新从原始 byte 数组开始进行注入。