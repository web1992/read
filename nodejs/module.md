# module

> file demo.js

```js
var 1
```

run `node demo.js` you can get this error

```js
(function (exports, require, module, __filename, __dirname) { var 1
....
```

That's why you can use `require('.fs')` in node