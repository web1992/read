# lambda

## 参考文章：

- [optional](https://unmi.cc/proper-ways-of-using-java8-optional/)
- [java-8-tutorial](http://winterbe.com/posts/2014/03/16/java-8-tutorial/)
- [lambda (from oracle)](https://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html)

## Method References

- [Method References](https://docs.oracle.com/javase/tutorial/java/javaOO/methodreferences.html)

Kind                                                    |   Example
----                                                    |   -------
Reference to a static method                            |   ContainingClass::staticMethodName
Reference to an instance method of a particular object  |	containingObject::instanceMethodName
Reference to an instance method of an arbitrary object of a particular type |	ContainingType::methodName
Reference to a constructor                              |   ClassName::new

```java
        List<String> list=new ArrayList<>();
        list.sort(String::compareToIgnoreCase);

        String lambda="lambda";
        // a = str1.compareToIgnoreCase(str1)
        // int -> (b,c)
        // 符合这样的方法签名
        int a = lambda.compareToIgnoreCase(lambda);
```

## functional interface

A functional interface is any interface that contains only one abstract method. (A functional interface may contain one or more default methods or static methods.)

1. any interface that contains only one abstract method
2. may contain one or more default methods or static methods
3. Because a functional interface contains only one abstract method, you can omit the name of that method when you implement it