# ForkJoinPool


> 关键字：

- work-stealing algorithm


## Basice Use

```
if (my portion of the work is small enough)
  do the work directly
else
  split my work into two pieces
  invoke the two pieces and wait for the results
```

## RecursiveTask

```java
class Fibonacci extends RecursiveTask<Integer> {  
      final int n;    
      Fibonacci(int n) {
         this.n = n; 
      }   
       protected Integer compute() {  
            if (n <= 1)        return n;   

            Fibonacci f1 = new Fibonacci(n - 1);  
            f1.fork();   

            Fibonacci f2 = new Fibonacci(n - 2);  
            return f2.compute() + f1.join();   
        }  
}
```

## Links

- [ForkJoinPool (from java api docs)](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ForkJoinPool.html)
- [ForkJoinPool (from oracle)](https://docs.oracle.com/javase/tutorial/essential/concurrency/forkjoin.html)
- [正确的使用 frok join](https://www.liaoxuefeng.com/article/1146802219354112)

