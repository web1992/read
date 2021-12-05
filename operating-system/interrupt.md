# 系统中断

## 

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