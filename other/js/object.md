# Object

## Object initializer

对象的初始化

- [Object initializer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Object_initializer)

## 对象初始化的三种方式

Objects can be initialized using `new Object()`, `Object.create()`, or using the `literal notation (initializer notation)`. An object initializer is a comma-delimited list of zero or more pairs of property names and associated values of an object, enclosed in curly braces ({}).

demo

```js
var obj1 = new Object();
var obj2 = Object.create({});
var obj3 = {};

console.log(obj1);
console.log(obj2);
console.log(obj3);
```

## Object.defineProperty

- [defineProperty](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty)