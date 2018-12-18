# new

- [new](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/new)

- It creates a brand new object out of thin air.
- It links `this` object to another object
- the newly created object from Step 1 gets passed as the `this` context
- if the function doesn't return it's own object, `this` is returned

Creating a user-defined object requires two steps:

1. Define the object type by writing a function.
2. Create an instance of the object with new.

When the code new Foo(...) is executed, the following things happen:

- A new object is created, inheriting from Foo.prototype.
- The constructor function Foo is called with the specified arguments, and with this bound to the newly created object. new Foo is equivalent to new Foo(), i.e. if no argument list is specified, Foo is called without arguments.
- The object (not null, false, 3.1415 or other primitive types) returned by the constructor function becomes the result of the whole new expression. If the constructor function doesn't explicitly return an object, the object created in step 1 is used instead. (Normally constructors don't return a value, but they can choose to do so if they want to override the normal object creation process.)

> If you didn't write the new operator, the Constructor Function would be invoked like any Regular Function, without creating an Object. In this case, the value of this is also different.

创建对象的两种方式 factory function 和 construct function

## factory function

```js
// factory function
function person(name) {
  return {
    name: name,
    say: function() {
      console.log("Hello I am ", name);
    }
  };
}

let lucy = person("Lucy");

lucy.say();
```

## construct function

```js
// construct function
function Car(name) {
  // use new ,this is Car
  // not use new ,this is window
  console.log("this", this);
  this.name = name;
  this.run = function() {
    console.log("run");
  };
  // return this;
}

// use new key word
let carBmw = new Car("BMW");
carBmw.run();

// not use new

let carBen = Car("Ben");
// carBen.run(); // will get error
```
