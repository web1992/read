# undefined

- [undefined from mozilla](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/undefined)

## sectionDifference between null and undefined

```js
typeof null; // "object" (not "null" for legacy reasons)
typeof undefined; // "undefined"
null === undefined; // false
null == undefined; // true
null === null; // true
null == null; // true
!null; // true
isNaN(1 + null); // false
isNaN(1 + undefined); // true
```

`undefined` 是一个`值`也是一个`类型`

```js
let name;
console.log(name); // undefined
console.log(typeof name); //"undefined" 这里是字符串
coneole.log(name == typeof name); // false
```