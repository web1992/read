# java i++ 与 ++i 的实现原理

本文从 java 的`字节码`角度，去探索一下 i++ 与++i 的实现原理

代码 1

```java
public class Test {
   public static void main(String[] args) {
      int q = 0;
      q = q++;
      System.out.println(q); // 输出结果 0
  }
}
```

代码 2

```java
public class Test {
  public static void main(String[] args) {  
               int q = 0;
               q = ++q;
               System.out.println(q);// 输出结果 1
  }
}
```

## JVM Opcode Reference

出现这个现象的原因是由 java 的编译之后的`操作码`决定的编译之后的顺序不同 JVM Opcode Reference

运行下面命令，查看反编译之后的操作码（指令码）

`javap -c Test`

代码 1 的反编译

```jvm
Code:
0: iconst_0
1: istore_1
2: iload_1
3: iinc   1, 1
6: istore_1
7: getstatic  #2
10: iload_1
11: invokevirtual #3
14: return
```

代码 2 的反编译

```jvm
Code:
0: iconst_0
1: istore_1
2: iinc          1, 1
5: iload_1
6: istore_1
7: getstatic     #2
10: iload_1
11: invokevirtual #3
14: return
```

## 指令

关于指令解释，可参照
[JVM Opcode Reference](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html)

下面是 `jvm` 指令的含义

```jvm
   iconst_0 // Pushing constants onto the stack
   istore_1 // Pop stack into local var
   iload_1  // Load integer from local variable n
   iinc     // Increment local var.
```

## 代码 1 的执行流程

`iconst_0` Pushing constants onto the stack

| index | stack | local var |
| ----- | ----- | --------- |
| 0     | 0     |           |
| 1     |       |           |

`istore_1` Pop stack into local var

| index | stack | local var |
| ----- | ----- | --------- |
| 0     |       | 0         |
| 1     |       |           |

`iload_1` Load integer from local variable n

| index | stack | local var |
| ----- | ----- | --------- |
| 0     | 0     | 0         |
| 1     |       |           |

`iinc 1, 1` Increment local var.

| index | stack | local var |
| ----- | ----- | --------- |
| 0     | 0     | 1         |
| 1     |       |           |

`istore_1` Pop stack into local var

**这里是重点，用 stack 的至覆盖了局部变量的值，**

| index | stack | local var |
| ----- | ----- | --------- |
| 0     |       | 0         |
| 1     |       |           |

`getstatic` 是调用方法

`iload_1` Load integer from local variable n

从局部变量取值，局部变量的值是 0，那么`q++`的结果也就是`0`

| index | stack | local var |
| ----- | ----- | --------- |
| 0     |       | 0         |
| 1     |       |           |

## 代码 2 的执行流程

`iconst_0` Pushing constants onto the stack

| index | stack | local var |
| ----- | ----- | --------- |
| 0     | 0     |           |
| 1     |       |           |

`istore_1` Pop stack into local var

| index | stack | local var |
| ----- | ----- | --------- |
| 0     |       | 0         |
| 1     |       |           |

`iinc 1, 1` Increment local var.

| index | stack | local var |
| ----- | ----- | --------- |
| 0     |       | 1         |
| 1     |       |           |

`iload_1` Load integer from local variable n

| index | stack | local var |
| ----- | ----- | --------- |
| 0     | 1     | 1         |
| 1     |       |           |

`istore_1` Pop stack into local var

| index | stack | local var |
| ----- | ----- | --------- |
| 0     |       | 1         |
| 1     |       |           |

`getstatic` 是调用方法

`iload_1` Load integer from local variable n

从局部变量取值，局部变量的值是 0，那么`++1`的结果也就是`1`

| index | stack | local var |
| ----- | ----- | --------- |
| 0     | 1     | 1         |
| 1     |       |           |

## 这里需要明白几个概念

* 1.局部变量表，用来存在局部变量的

* 2.操作数栈 是进行算术运算的地方

* 3.在进行算术运算时，局部变量表与操作数栈是存在数据交互的

## 总结

其实可以这样理解，Java 中为了实现 `i++` 与 `++i`的计算结果不同语义，把`i++` 与 `++i` 编译成顺序不同的操作码，从而来实现`i++` 与 `++i`的不同的语义

可参考：["栈帧、局部变量表、操作数栈 http://wangwengcn.iteye.com/blog/1622195"](http://wangwengcn.iteye.com/blog/1622195)
