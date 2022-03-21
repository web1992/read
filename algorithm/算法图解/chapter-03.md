# 第三章 递归

- 分而治之
- 基线条件 base case
- 递归条件 recursive case
- 递归条件指的是函数调用自己
- 栈


```python
def countdown(i):
    print i
    if i <= 0: // 基线条件
        return
    else:
        countdown(i-1) // 递归条件
```

## 小结

- 递归指的是调用自己的函数。
- 每个递归函数都有两个条件：基线条件和递归条件。
- 栈有两种操作：压入和弹出。
- 所有函数调用都进入调用栈。
- 调用栈可能很长，这将占用大量的内存
