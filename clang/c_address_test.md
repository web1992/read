# 地址测试

```c
int main(int argc, char* argv[]){
    int i = 0;
    int arr[3] = {0};
    for(; i<3; i++){
        arr[i] = 0;
        printf("hello world\n");
    }
    int m=0;
    printf("argc:%p\n",&argc);
    printf("argv:%p\n",&argv);
    printf("i:  %p\n",&i);
    printf("arr:%p\n",&arr);
    printf("[0]:%p\n",&arr[0]);
    printf("[1]:%p\n",&arr[1]);
    printf("[2]:%p\n",&arr[2]);
    printf("m:  %p\n",&m);
    return 0;
}
```

输出：

```
hello world
hello world
hello world
argc:0x7ffe5f92e08c
argv:0x7ffe5f92e080
i:  0x7ffe5f92e0ac
arr:0x7ffe5f92e0a0
[0]:0x7ffe5f92e0a0
[1]:0x7ffe5f92e0a4
[2]:0x7ffe5f92e0a8
m:  0x7ffe5f92e09c
```

注意：数组的地址，arr[0]的地址是 `0x7fffe926d520` arr[1]的地址是 `0x7fffe926d524`
