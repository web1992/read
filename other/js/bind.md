# bind

- [bind mozilla](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind)
- [bind javascript.info](https://javascript.info/bind)

Method `func.bind(context, ...args)` returns a "bound variant" of function func that fixes the context this and first arguments if given.

Usually we apply bind to fix this in an object method, so that we can pass it somewhere. For example, to `setTimeout`. There are more reasons to bind in the modern development, we’ll meet them later.

## demo

```js
var module = {
  x: 42,
  getX: function() {
    return this.x;
  }
};

var unboundGetX = module.getX;
console.log(unboundGetX()); // The function gets invoked at the global scope
// expected output: undefined

var boundGetX = unboundGetX.bind(module);
console.log(boundGetX());
// expected output: 42
```
