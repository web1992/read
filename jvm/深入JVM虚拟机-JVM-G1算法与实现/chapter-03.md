# 第 3 章　转移

- SATB 队列集合主要用来记录标记过程中对象之间引用关系的变化
- 而转移专用记忆集合则用来记录区域之间的引用关系
- G1GC 是通过卡表（card table）来实现转移专用记忆集合的
- evacuation 转移
- mutator 线程=用户线程
- 转移专用记忆集合维护线程
- 热卡片 hot card
- 卡片计数表
- 热队列中的卡片会被留到转移的时候再处理
- 回收集合(collection set)
- forwarding 指针

## 转移专用记忆集合

通过使用转移专用记忆集合，在转移时即使不扫描所有区域内的对象，也可以查到待转移对象所在区域内的对象`被其他区域引用`的情况，从而简化单个区域的转移处理

转移专用记忆集合中记录了来自其他区域的引用，因此即使不扫描所有区域内的对象，也可以确定待转移对象所在区域内的存活对象。

G1GC 是通过卡表（card table）来实现转移专用记忆集合的。

## 卡表

![card-table.drawio.svg](./images/card-table.drawio.svg)


卡表的实体是数组。数组的元素是 1B 的卡片，对应了堆中的 512B。
脏卡片用灰色表示，净卡片用白色表示。

堆中的对象所对应的卡片在卡表中的索引值可以通过以下公式快速计算出来。

> (对象的地址－堆的头部地址)／512

因为卡片的大小是 1B，所以可以用来表示很多状态。

卡片的种类很多，本书主要关注以下两种。

- ①净卡片
- ②脏卡片

## 卡表和记忆集

![mset-card-table.drawio.svg](./images/mset-card-table.drawio.svg)

每个区域都有一个转移专用记忆集合，它是通过散列表实现的。图中对象 b 引用了对象 a，因此对象 b 所对应的卡片索引就被记录在了区域 A 的转移专用记忆集合中。

## 转移执行步骤

转移的执行步骤为以下 3 个。

- ①选择回收集合
- ②根转移
- ③转移

- ①是指参考并发标记提供的信息来选择被转移的区域。被选中的区域称为回收集合（collection set）。
- ②是指将回收集合内由根直接引用的对象，以及被其他区域引用的对象转移到空闲区域中。
- ③是指以②中转移的对象为起点扫描其子孙对象，将所有存活对象一并转移。当③结束之后，回收集合内的所有存活对象就转移完成了

这 3 个步骤都是暂停处理。在转移开始后，即使并发标记正在进行也会先中断，而优先进行转移处理。

另外，②和③其实都是可以由多个线程并行执行的，但是为了便于读者理解，本书进行了简化，是以单线程执行为前提展开讨论的。


### 步骤①——选择回收集合

本步骤的主要工作是选择回收集合。选择标准简单来说有两个。
- ①转移效率高
- ②转移的预测暂停时间在用户的容忍范围内

在选择回收集合时，堆中的区域已经在 2.8 节的步骤⑤中按照转移效率被降序排列了。接下来，按照排好的顺序依次计算各个区域的预测暂停时间，并选择回收集合。当所有已选区域预测暂停时间的总和快要超过用户的容忍范围时，后续区域的选择就会停止，所有已选区域成为 1 个回收集合。关于转移的预测暂停时间，4.2 节将详细介绍。

G1GC 中的 G1 是 Garbage First 的简称，所以 G1GC 的中文意思是“垃圾优先的垃圾回收”。而回收集合的选择，会以转移效率由高到低的顺序进行。在多数情况下，死亡对象（垃圾）越多，区域的转移效率就越高，因此 G1GC 会优先选择垃圾多的区域进入回收集合。这就是 G1GC名称的由来。


### 步骤②——根转移

根转移的转移对象包括以下 3 类

- ①由根直接引用的对象
- ②并发标记处理中的对象
- ③由其他区域对象直接引用的回收集合内的对象


### 