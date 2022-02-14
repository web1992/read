# volatile

volatile （底层是各种内存屏障）内存屏障有两个作用：

阻止屏障两侧的指令重排序；
强制把写缓冲区/高速缓存中的脏数据等写回主内存，让缓存中相应的数据失效。

## Links

- [内存屏障](https://www.jianshu.com/p/2ab5e3d7e510)