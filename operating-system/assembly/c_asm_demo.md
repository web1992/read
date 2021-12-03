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
	.file	"main.c"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	$0, -4(%rbp)
	jmp	.L2
.L3:
	addl	$1, -4(%rbp)
.L2:
	cmpl	$9, -4(%rbp)
	jle	.L3
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (GNU) 4.8.5 20150623 (Red Hat 4.8.5-44)"
	.section	.note.GNU-stack,"",@progbits
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

十进制与二进制互换:
29=16+8+4+1=b11101
二进制换十六进制，四位一组:
111011 = 11'1011 = 0x3b

补码的好处是:
1. +0， -0在系统中的表示法是一样的，而原码和反码都做不到;
2.负数的运算可以复用正数的加法器，不需要额外的电路。