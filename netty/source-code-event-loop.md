# EventLoop

## 1. NioEventLoop

类图继承关系：

![NioEventLoop](./images/NioEventLoop.png)

从这个类图种可以看到`NioEventLoop`的作用：

1. 继承了`ExecutorService`,因此可以作为一个线程池,执行提交的任务
2. 继承了`ScheduledExecutorService`,  因此可以进行`定时`任务的执行
3. 继承了`EventLoopGroup`

下面从这几个方面进行分析：

1. EventLoop 的初始化
2. EventLoop 的线程模型
3. EventLoop 进行事件的分发
4. EventLoopGroup

## NioEventLoopGroup

NioEventLoopGroup 的类图

![NioEventLoopGroup](./images/NioEventLoopGroup.png)

## 参考资料

- [eventLoop(开源中国)](https://my.oschina.net/andylucc/blog/618179)
- [eventLoop(segmentfault)](https://segmentfault.com/a/1190000007403873)
