# stream

## 特点

- 声明式 更简洁，更易读
- 可复合 更灵活
- 可并行 性能更好
- 只能便利一次

## 流的方法

`Person` 类型定义

```java
    static class Person{

        public Person(String name, Integer age) {
            this.name = name;
            this.age = age;
        }

        @Override
        public String toString() {
            return "Person{" + "name='" + name + '\'' + ", age=" + age + '}';
        }

        private String name;
        private Integer age;

        public Integer getAge() {
            return age;
        }

        public void setAge(Integer age) {
            this.age = age;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }
    }
```

### filter

```java
    List<String> list= Arrays.asList("java","stream","filter");
    List<String> afterList = list
                        .stream()
                        .filter(str -> str.length() > 4)
                        .collect(toList());
    System.out.println(afterList);
    // [stream, filter]
```

### distinct

```java
    List<String> wordList = Arrays.asList("stream", "java", "java8", "stream", "lambda");
    List<String> collect = wordList.stream().distinct().collect(Collectors.toList());
    System.out.println(collect);
    // [stream, java, java8, lambda]
```

### limit

```java
    List<String> wordList = Arrays.asList("stream", "java", "java8", "stream", "lambda");
    List<String> collect = wordList.stream().limit(3).collect(Collectors.toList());
    System.out.println(collect);
    // [stream, java, java8]
```

### skip

```java
    List<String> wordList = Arrays.asList("stream", "java", "java8", "stream", "lambda");
    List<String> collect = wordList.stream().skip(2).collect(Collectors.toList());
    System.out.println(collect);
    // [java8, stream, lambda]]
```

### map

```java
    // 统计字符串的长度
    List<String> wordList = Arrays.asList("stream", "java", "java8", "stream", "lambda");
    List<Integer> collect = wordList.stream().map(String::length).collect(Collectors.toList());
    System.out.println(collect);
    // [6, 4, 5, 6, 6]
```

### flatMap

```java

```

### sorted

```java
    // 自然顺序
    List<String> wordList = Arrays.asList("6", "2", "3", "3", "5");
    List<String> collect = wordList.stream().sorted().collect(Collectors.toList());
    System.out.println(collect);
    // [2, 3, 3, 5, 6]

    // sorted use Comparator
    List<Person> wordList = Arrays.asList(new Person("Bill Gates",63),new Person("Steve Jobs",56),new Person("web1992",25));
    List<Person> collect = wordList.stream().sorted(Comparator.comparing(Person::getAge)).collect(Collectors.toList());
    System.out.println(collect);
    // [Person{name='web1992', age=25}, Person{name='Steve Jobs', age=56}, Person{name='Bill Gates', age=63}]
```

### anyMatch

### noneMatch

### allMatch

### findAny

### findFirst

### forEach

### collect

### reduce

`Optional<T> reduce(BinaryOperator<T> accumulator);`

```java
        boolean foundAny = false;
        T result = null;
        for (T element : this stream) {
             if (!foundAny) {
                 foundAny = true;
                  result = element;
              }
              else{
               result = accumulator.apply(result, element);
              }
         }
        return foundAny ? Optional.of(result) : Optional.empty();
```

`T reduce(T identity, BinaryOperator<T> accumulator);`

```java
         T result = identity;
         for (T element : this stream)
              result = accumulator.apply(result, element)
         return result;
```

### count
