# 系统中断

关键字：

- 页中断 写保护中断和缺页中断
- MMU 单元
- fork 原理：写保护中断与写时复制
- 写时复制 (Copy On Write， COW)
- execve 系统调用
- execve 原理：缺页中断

如果物理页不在内存中，或者页表未映射，或者读写请求不满足页表项内的权限定义时，MMU 单元就会产生一次中断。

## Demo

```c
// 通过系统中断，打印
// compile command : gcc -o hello hello.c
void sayHello() {
    const char* s = "hello\n";
    __asm__("int $0x80\n\r"
            ::"a"(4), "b"(1), "c"(s), "d"(6):);
}

int main() {
    sayHello();
    return 0;
}
```

## Links

- [系统中断简介](https://www.jianshu.com/p/f09ebc197bac)
- [中断详解](https://mp.weixin.qq.com/s?__biz=Mzk0MjE3NDE0Ng==&mid=2247498208&idx=1&sn=b784f8b4e627ebd1bfb9810d194fdb80&chksm=c2c5834df5b20a5bdee331002bfc61c90eb468da325bf67abeef780c303a9f51c8543e1a5981&scene=21#wechat_redirect)