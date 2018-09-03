# lambda

## 参考文章：

- [optional](https://unmi.cc/proper-ways-of-using-java8-optional/)
- [java-8-tutorial](http://winterbe.com/posts/2014/03/16/java-8-tutorial/)
- [lambda (from oracle)](https://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html)

## 方法引用

```java
List<String> list=new ArrayList<>();
list.sort(String::compareToIgnoreCase);
```