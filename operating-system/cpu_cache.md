# CPU 缓存

关键字：

- store buffer
- 失效队列 invalid queue
- 伪共享
- L1 L2 L3
- 缓存一致性
- VI 协议
- MESI 协议
- 内存屏障
- 读屏障
- 写屏障
- 异质（Heterogeneity）式
- 非一致性访存（Non-uniform memory access，NUMA）
- IO 端口主要用于状态读取和设置等控制命令的通讯，而 IO 内存映射主要用于大量的数据传输。
- 前端总线（Front Side Bus，FSB）
- 单向屏障 (half-way barrier)

在多核芯片上，缓存集成的方式主要有以下三种：

- 集中式缓存：一个缓存和所有处理器直接相连，多个核共享这一个缓存；
- 分布式缓存：一个处理器仅和一个缓存相连，一个处理器对应一个缓存；
- 混合式缓存：在 L3 采用集中式缓存，在 L1 和 L2 采用分布式缓存。

## 伪共享

伪共享（false-sharing）的意思是说，当两个线程同时各自修改两个相邻的变量，由于缓存是按缓存块来组织的，当一个线程对一个缓存块执行写操作时，必须使其他线程含有对应数据的缓存块无效。这样两个线程都会同时使对方的缓存块无效，导致性能下降。

```c++
#include <stdio.h>
#include <pthread.h>
 
struct S{
   long long a;
   long long b;
} s;
 
void *thread1(void *args)
{
    for(int i = 0;i < 100000000; i++){
        s.a++;
    }
    return NULL;
}
 
void *thread2(void *args)
{
    for(int i = 0;i < 100000000; i++){
        s.b++;
    }
    return NULL;
}
 
int main(int argc, char *argv[]) {
    pthread_t t1, t2;
    s.a = 0;
    s.b = 0;
    pthread_create(&t1, NULL, thread1, NULL);
    pthread_create(&t2, NULL, thread2, NULL);
    pthread_join(t1, NULL);
    pthread_join(t2, NULL);
    printf("a = %lld, b = %lld\n", s.a, s.b);
    return 0;
}
```

## 缓存一致性

- VI 协议
- MESI 协议

## 缓存写策略

- 写回（Write Back）和写直达（Write Through）
- 写更新（Write Update）和写无效（Write Invalidate）。
- 写分配（Write Allocate）和写不分配（Not Write Allocate）。

从缓存和内存的更新关系看，写策略分为写回和写直达；
从写缓存时 CPU 之间的更新策略来看，写策略分为写更新和写无效；
从写缓存时数据是否被加载来看，写策略又分为写分配和写不分配。

## MESI

缓存块的状态分为 4 种，也是 MESI 协议名字的由来：

- Modified（M）：缓存块有效，但是是“脏”的，其数据与主存中的原始数据不同，同时还表示处理器对于该缓存块的唯一所有权，表示数据只在这个处理器的缓存上是有效的；
- Exclusive（E）：缓存块是干净有效且唯一的；
- Shared（S）：缓存块是有效且干净的，有多个处理器持有相同的缓存副本；
- Invalid（I）：缓存块无效。

## 内存屏障

```c
// CPU0
void foo() {
    a = 1;
    smp_mb();
    b = 1;
}

// CPU1
void bar() {
    while (b == 0) continue;
    assert(a == 1);
}
```

屏障的作用是前边的读写操作未完成的情况下，后面的读写操作不能发生

- dmb Data Memory Barrier
- 读屏障
- 写屏障
- 更加精细地控制 store buffer 和 invalid queue 的顺序。
- StoreStore barrier
- LoadLoad barrier
- 单向屏障 (half-way barrier)


## 读写屏障分离

分离的写屏障和读屏障的出现，是为了更加精细地控制 store buffer 和 invalid queue 的顺序。

再具体一点，写屏障的作用是让屏障前后的写操作都不能翻过屏障。也就是说，写屏障之前的写操作一定会比之后的写操作先写到缓存中。

读屏障的作用也是类似的，就是保证屏障前后的读操作都不能翻过屏障。假如屏障的前后都有缓存失效的信息，那屏障之前的失效信息一定会优先处理，也就意味着变量的新值一定会被优先更新。

## NUMA

这里的一致性是指，同一个 CPU 对所有内存的访问的速度是一样的，因为物理内存是连续且集中的。

而非一致性是指，内存在物理上被分为了多个节点 node，CPU 可以访问所有节点，但是为了提升访问效率，CPU 可以有选择地优先访问离自己近的内存节点

## Links

- [CPU 缓存](https://mp.weixin.qq.com/s/GtzSAblSTxHgi_t89mCqjQ)