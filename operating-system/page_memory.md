# Page and Memory

- CPU 的内存管理单元 (Memory Management Unit, MMU)
- PTE 页表项 (Page Table Entry)
- PDE 页目录项 (Page Directory Entry)
- 虚拟地址找到物理内存中的真实位置
- cr3 寄存器 (x86)
- 段寄存器
- 物理地址 = 段地址x16+偏移地址 (物理地址 = 段寄存器 << 4 + 段内偏移)
- 页面的换入换出
- 局部性原理：空间局部性 时间局部性
- 硬盘上的 swap 区域
- 缺页中断
- 保护模式
- 实模式
- 每个进程都有自己的页表
- 64位CPU地址：9位，9位，9位和12位四段
- 段式管理和中断的管理
- x86 指令集
- 实模式（Real Mode）
- ds 做为数据段寄存器
- ss 栈基址寄存器
- 代码段的地址放到 cs 寄存器
- 段式管理和页式管理
- 保护模式（Protection Mode)
- 全局描述符表（Global Descriptor Table, GDT)
- GDTR 寄存器 -> GDT 的地址
- 中断描述符表（Interruption Description Table, IDT）
- Fault、Trap、Abort 以及普通中断
- IDT 的基地址存储在 idtr 寄存器中

## 虚拟地址 物理地址

- 第一步是确定页目录基址
- 第二步是定位页目录项（PDE）
- 第三步是定位页表项（PTE）
- 最后一步是确定真实的物理地址

第一步是确定页目录基址。每个 CPU 都有一个页目录基址寄存器，最高级页表的基地址就存在这个寄存器里。在 X86 上，这个寄存器是 CR3。每一次计算物理地址时，MMU 都会从 CR3 寄存器中取出页目录所在的物理地址。
第二步是定位页目录项（PDE）。一个 32 位的虚拟地址可以拆成 10 位，10 位和 12 位三段，上一步找到的页目录表基址加上高 10 位的值乘以 4，就是页目录项的位置。这是因为，一个页目录项正好是 4 字节，所以 1024 个页目录项共占据 4096 字节，刚好组成一页，而 1024 个页目录项需要 10 位进行编码。这样，我们就可以通过最高 10 位找到该地址所对应的 PDE 了。

第三步是定位页表项（PTE）。页目录项里记录着页表的位置，CPU 通过页目录项找到页表的位置以后，再用中间 10 位计算页表中的偏移，可以找到该虚拟地址所对应的页表项了。页表项也是 4 字节的，所以一页之内刚好也是 1024 项，用 10 位进行编码。所以计算公式与上一步相似，用页表基址加上中间 10 位乘以 4，可以得到页表项的地址。

最后一步是确定真实的物理地址。上一步 CPU 已经找到页表项了，这里存储着物理地址，这才真正找到该虚拟地址所对应的物理页。虚拟地址的低 12 位，刚好可以对一页内的所有字节进行编码，所以我们用低 12 位来代表页内偏移。计算的公式是物理页的地址直接加上低 12 位

## 虚拟内存

虚拟内存主要有下面两个特点：
第一，由于每个进程都有自己的页表，所以每个进程的虚拟内存空间就是相互独立的。进程也没有办法访问其他进程的页表，所以这些页表是私有的。这就解决了多进程之间地址冲突的问题。
第二，PTE 中除了物理地址之外，还有一些标记属性的比特，比如控制一个页的读写权限，标记该页是否存在等。在内存访问方面，操作系统提供了更好的安全性。

![memory.drawio.svg](./images/memory.drawio.svg)

## 页面切换

1. 每个进程都有一个管理结构，在linux中就是 task_struct ，它会记录页表的起始地址:pgdir，然后每次进程切换时都会把目标的页表起始地址送入CR3寄存器。
2. 进程自己是不知道的，但是内核知道。内核管理着全部的物理内存，哪一块分配给谁，它是非常清楚的。用于管理物理内存的结构叫做mem_map，如果有兴趣的话可以自己查一下。

## 分段

其实，内存并没有分段，段的划分来自于CPU，由于8086CPU 用“基础地址(段地址x16)+偏移地址=物理地址”的方式给出内存单元的物理地址，使得我们可以用分段的方式来管理内存。