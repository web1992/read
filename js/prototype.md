# prototype

## 定义

`Function.prototype`

## Inheritance and the prototype chain

js 中使用 prototype 链实现继承

- [Inheritance and the prototype chain](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Inheritance_and_the_prototype_chain)

`Person.prototype` is an object shared by all instances of `Person`. It forms part of a lookup chain (that has a special name, "prototype chain"): any time you attempt to access a property of Person that isn't set, JavaScript will check Person.prototype to see if that property exists there instead. As a result, `anything` assigned to Person.prototype becomes available to all instances of that constructor via the this object.

## Inheriting properties Section

## Inheriting "methods" Section

## demo

```js
// f 必须是一个function
let f = function() {
  this.a = 1;
  this.b = 2;
};
let o = new f(); // {a: 1, b: 2}
// o.prototype.a=1; o 是一个对象，因此报错
// add properties in f function's prototype
f.prototype.b = 3;
f.prototype.c = 4;
```

## new with prototype

当进行 `var foo = new Foo()` 操作的时候，foo 会继承`Foo.prototype`原型链

因此下面的例子中，`doSomeInstancing`的`__proto__` 指向了`doSomething.prototype`

> A new object is created, inheriting from Foo.prototype

```js
function doSomething() {}
typeof doSomething;
doSomething.prototype.foo = "bar"; // add a property onto the prototype
var doSomeInstancing = new doSomething();
doSomeInstancing.prop = "some value"; // add a property onto the object
typeof doSomeInstancing;
console.log(doSomeInstancing);
```

This results in an output similar to the following:

```js
{
    prop: "some value",
    __proto__: {
        foo: "bar",
        constructor: ƒ doSomething(),
        __proto__: {
            constructor: ƒ Object(),
            hasOwnProperty: ƒ hasOwnProperty(),
            isPrototypeOf: ƒ isPrototypeOf(),
            propertyIsEnumerable: ƒ propertyIsEnumerable(),
            toLocaleString: ƒ toLocaleString(),
            toString: ƒ toString(),
            valueOf: ƒ valueOf()
        }
    }
}
```
