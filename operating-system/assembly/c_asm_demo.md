# 汇编

```c
int main(){
    int i=0;
    while(i<10){
        i++;
    }
}
```

```sh
# 输出汇编
gcc -S  main.c
# 查看汇编
cat main.s
```

```s
main:
.LFB0:
	pushq	%rbp
	movq	%rsp, %rbp
	movl	$0, -4(%rbp) # 给变量i赋值为0(变量i放在栈的-4的位置)
	jmp	.L2
.L3:
	addl	$1, -4(%rbp)
.L2:
	cmpl	$9, -4(%rbp)
	jle	.L3
	popq	%rbp
	ret
```

```sh
objdump -d a.out
```

```s
00000000004004ed <main>:
  4004ed:	55                   	push   %rbp
  4004ee:	48 89 e5             	mov    %rsp,%rbp
  4004f1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  4004f8:	eb 04                	jmp    4004fe <main+0x11>
  4004fa:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  4004fe:	83 7d fc 09          	cmpl   $0x9,-0x4(%rbp)
  400502:	7e f6                	jle    4004fa <main+0xd>
  400504:	5d                   	pop    %rbp
  400505:	c3                   	retq
  400506:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  40050d:	00 00 00
```
