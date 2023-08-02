# Java 8

## 简介

- 如何去理解+使用 Lambda `函数式编程`
- 从匿名内部类 到 Lambda 到方法引用
- Lambda 在Stream 中的使用。
- 实现原理
- 方法引用

## 鸭子类型

鸭子类型（英语：duck typing）在程序设计中是动态类型的一种风格。在这种风格中，一个对象有效的语义，不是由继承自特定的类或实现特定的接口，而是由"当前方法和属性的集合"决定。这个概念的名字来源于由`詹姆斯·惠特科姆·莱利`提出的鸭子测试 “鸭子测试”可以这样表述：
“当看到一只鸟走起来像鸭子、游泳起来像鸭子、叫起来也像鸭子，那么这只鸟就可以被称为鸭子。

## Thread 中的应用

```java
public static void main(String[] args) {

    System.setProperty("jdk.internal.lambda.dumpProxyClasses", ".");

    new Thread(LambdaTest2::run).start();

}


public static void run() {
    System.out.println(Thread.currentThread().getName() + " run ...");
}

```

## ThreadLocal 中的应用

```java
public static final ThreadLocal<Object> TC_OBJ = ThreadLocal.withInitial(Object::new);

public static final ThreadLocal<Map<?, ?>> TC_MAP = ThreadLocal.withInitial(HashMap::new);

```

## 好的例子

```java
List<Long> detailIdList = dOList.stream()
                .filter(this::aa)
                .map(this::bb)
                .distinct().collect(Collectors.toList());

```


## 底层原理

- invokedynamic
- BootstrapMethods
- LambdaMetafactory.metafactory
- Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle


## 其他

- idea 优化
- 使用lambda会有性能损失吗
- lambda vs 匿名内部类

## Links

- [https://colobu.com/2014/11/06/secrets-of-java-8-lambda/#LambdaMetafactory-metafactory](https://colobu.com/2014/11/06/secrets-of-java-8-lambda/#LambdaMetafactory-metafactory)
- [https://www.baeldung.com/java-method-handles](https://www.baeldung.com/java-method-handles)
- [http://cr.openjdk.java.net/~briangoetz/lambda/lambda-translation.html](http://cr.openjdk.java.net/~briangoetz/lambda/lambda-translation.html)
- [http://cr.openjdk.java.net/~briangoetz/lambda/lambda-state-final.html](http://cr.openjdk.java.net/~briangoetz/lambda/lambda-state-final.html)
- [理解 invokedynamic](https://www.jianshu.com/p/d74e92f93752)