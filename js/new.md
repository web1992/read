# new

- [new](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/new)

创建对象的两种方式 actory function 和 construct function

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
