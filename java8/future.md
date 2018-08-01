# Future

## CompletableFuture

## 常用的方法

```java
    public static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier) {
        return asyncSupplyStage(asyncPool, supplier);
    }


    public static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier,
                                                       Executor executor) {
        return asyncSupplyStage(screenExecutor(executor), supplier);
    }


    public boolean complete(T value) {
        boolean triggered = completeValue(value);
        postComplete();
        return triggered;
    }

    public boolean completeExceptionally(Throwable ex) {
        if (ex == null) throw new NullPointerException();
        boolean triggered = internalComplete(new AltResult(ex));
        postComplete();
        return triggered;
    }
```

## demo

```java
    List<Person> personList = new ArrayList<>();
    List<CompletableFuture<String> listName =  personList.stream()
              // 耗时的异步计算
              .map(person -> CompletableFuture.supplyAsync(person::getCar,executor))
              // 非耗时的同步计算
              .map(future -> future.thenApply(Car::getCompany))
              // 耗时的异步计算
              .map(future -> future.thenCompose(company ->
                                CompletableFuture.supplyAsync(Company::getName(company))))
              .collect(toList());
    // 收集CompletableFuture中所有的结果
    listName.stream.map(CompletableFuture::join).collect(toList());
```
