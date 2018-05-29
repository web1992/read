# introduction

some summary of [introduction to javascript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/A_re-introduction_to_JavaScript)

## data type

* Number
* String
* Boolean
* Symbol (new in ES2015)
* Object
  * Function
  * Array
  * Date
  * RegExp
* null
* undefined

And there are some built-in [Error](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error) types as well. Things are a lot easier if we stick with the first diagram, however, so we'll discuss the types listed there for now.

## Other typesEdit

**JavaScript distinguishes between null, which is a value that indicates a deliberate non-value (and is only accessible through the null keyword), and `undefined`, which is a value of type `undefined` that indicates an uninitialized value — that is, a value hasn't even been assigned yet.** We'll talk about variables later, but in JavaScript it is possible to declare a variable without assigning a value to it. If you do this, the variable's type is `undefined`. `undefined` is actually a constant.

JavaScript has a boolean type, with possible values true and false (both of which are keywords.) Any value can be converted to a boolean according to the following rules:

`false`, `0`, empty `strings` (""), `NaN`, `null`, and `undefined` all become false.
All other values become true.

## Custom objects

```js
function makePerson(first, last) {
  return {
    first: first,
    last: last
  };
}
function personFullName(person) {
  return person.first + " " + person.last;
}
function personFullNameReversed(person) {
  return person.last + ", " + person.first;
}

s = makePerson("Simon", "Willison");
personFullName(s); // "Simon Willison"
personFullNameReversed(s); // "Willison, Simon"
```

This works, but it's pretty ugly. You end up with dozens of functions in your global namespace. What we really need is a way to attach a function to an object. Since functions are objects, this is easy

```js
function makePerson(first, last) {
  return {
    first: first,
    last: last,
    fullName: function() {
      return this.first + " " + this.last;
    },
    fullNameReversed: function() {
      return this.last + ", " + this.first;
    }
  };
}

s = makePerson("Simon", "Willison");
s.fullName(); // "Simon Willison"
s.fullNameReversed(); // "Willison, Simon"
```

There's something here we haven't seen before: the this keyword. Used inside a function, this refers to the current object. What that actually means is specified by the way in which you called that function. If you called it using dot notation or bracket notation on an object, that object becomes this. If dot notation wasn't used for the call, this refers to the global object.

> use this

```js
function Person(first, last) {
  this.first = first;
  this.last = last;
  this.fullName = function() {
    return this.first + " " + this.last;
  };
  this.fullNameReversed = function() {
    return this.last + ", " + this.first;
  };
}
var s = new Person("Simon", "Willison");
```
