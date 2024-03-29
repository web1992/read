# 第 10 章　分配器

- 最大 VM 堆
- G1GC堆
- 常驻内存空间
- 最大 VM 堆 = G1GC堆 + 常驻内存空间
- window linux 内存分配
- mmap
- TLAB（Thread Local Allocation Buffer，线程本地分配缓冲区）
- 字（word）数
- 字节数 byte

## Linux mmap

在 Linux 上，用来实现内存空间申请和分配的是mmap()。

Linux 中没有申请内存空间的概念，调用mmap()后就会分配内存空间。不过，分配内存空间后并非立即就会分配物理内存。只有在分配到的内存空间被访问时才会实际地发生物理内存分配。

## VM 堆中实现对齐的方法

VM 堆是以区域大小对齐的。也就是说，VM 堆的头地址是区域大小的整数倍。那么，在 HotSpotVM 中是如何实现对齐的呢？

其实，实现方法非常简单。为了便于说明，我们假设对齐大小（区域大小）为 1 KB，VM 堆的大小大于 1 KB。具体的对齐步骤如下所示（图10.5）。

- ①申请 VM 堆大小的内存空间
- ②记录在①的内存范围内且地址是 1 KB 的倍数的地址
- ③释放之前申请的内存空间
- ④指定通过②记录的地址，再次申请 VM 堆大小的内存空间
- ⑤如果④失败了，则返回到①重新开始

## 