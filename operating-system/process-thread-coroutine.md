# 进程+线程+协程

## 进程 线程

进程有自己独立的内存空间和页表，以及文件表等等各种私有资源，如果使用多进程系统，让多个任务并发执行，那么它所占用的资源就会比较多。线程的出现解决了这个问题。

同一个进程中的线程则共享该进程的内存空间，文件表，文件描述符等资源，它与同一个进程的其他线程共享资源分配。除了共享的资源，每个线程也有自己的私有空间，这就是线程的栈。线程在执行函数调用的时候，会在自己的线程栈里创建函数栈帧。根据上面所说的特点，人们常把进程看做是资源分配的单位，把线程才看成一个具体的执行实体。由于线程的切换过程和进程的切换过程十分相似，我们这节课就只以进程的切换为重点进行讲解，请你一定要自己查找相关资料，对照进程切换的过程，去理解线程的切换过程。

## 协程

协程是比线程更轻量的执行单元。进程和线程的调度是由操作系统负责的，而协程则是由执行单元相互协商进行调度的，所以它的切换发生在用户态。只有前一个协程主动地执行 yield 函数，让出 CPU 的使用权，下一个协程才能得到调度。因为程序自己负责协程的调度，所以大多数时候，我们可以让不那么忙的协程少参与调度，从而提升整个程序的吞吐量，而不是像进程那样，没有繁重任务的进程，也有可能被换进来执行。协程的切换和调度所耗费的资源是最少的，Go 语言把协程和 IO 多路复用结合在一起，提供了非常便捷的 IO 接口，使得协程的概念深入人心。从操作系统和 Web Server 演进的历史来看，先是多进程系统的出现，然后出现了多线程系统，最后才是协程被大规模使用，这个演进历程背后的逻辑就是执行单元需要越来越轻量，以支持更大的并发总数。

```cpp
// 协程实现
#include <stdio.h>
#include <stdlib.h>

#define STACK_SIZE 1024

typedef void(*coro_start)();

class coroutine {
public:
    long* stack_pointer;
    char* stack;

    coroutine(coro_start entry) {
        if (entry == NULL) {
            stack = NULL;
            stack_pointer = NULL;
            return;
        }

        stack = (char*)malloc(STACK_SIZE);
        char* base = stack + STACK_SIZE;
        stack_pointer = (long*) base;
        stack_pointer -= 1;
        *stack_pointer = (long) entry;
        stack_pointer -= 1;
        *stack_pointer = (long) base;
    }

    ~coroutine() {
        if (!stack)
            return;
        free(stack);
        stack = NULL;
    }
};

coroutine* co_a, * co_b;

void yield_to(coroutine* old_co, coroutine* co) {
    __asm__ (
        "movq %%rsp, %0\n\t"
        "movq %%rax, %%rsp\n\t"
        :"=m"(old_co->stack_pointer):"a"(co->stack_pointer):);
}

void start_b() {
    printf("B");
    yield_to(co_b, co_a);
    printf("D");
    yield_to(co_b, co_a);
}

int main() {
    printf("A");
    co_b = new coroutine(start_b);
    co_a = new coroutine(NULL);
    yield_to(co_a, co_b);
    printf("C");
    yield_to(co_a, co_b);
    printf("E\n");
    delete co_a;
    delete co_b;
    return 0;
}
```