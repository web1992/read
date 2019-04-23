# module

`module` `nodejs` 的内置函数

```js
// file demo.js
var 1
```

run `node demo.js` you can get this error

```js
(function (exports, require, module, __filename, __dirname) { var 1
// ....
```

That's why you can use `require('.fs')` in `nodejs`,`nodejs` wrap you `js` file

```js
// file demo.js
console.log("exports= ",exports);
console.log("require= ",require);
console.log("module= ",module);
console.log("__filename= ",__filename);
console.log("__dirname= ",__dirname);
```

run `node demo.js`

```js
exports=  {}
require=  function require(path) {
    try {
      exports.requireDepth += 1;
      return mod.require(path);
    } finally {
      exports.requireDepth -= 1;
    }
  }
module=  Module {
  id: '.',
  exports: {},
  parent: null,
  filename: '/Users/zl/Documents/dev/nodes/src/demo.js',
  loaded: false,
  children: [],
  paths:
   [ '/Users/zl/Documents/dev/nodes/src/node_modules',
     '/Users/zl/Documents/dev/nodes/node_modules',
     '/Users/zl/Documents/dev/node_modules',
     '/Users/zl/Documents/node_modules',
     '/Users/zl/node_modules',
     '/Users/node_modules',
     '/node_modules' ] }
__filename=  /Users/zl/Documents/dev/nodes/src/demo.js
__dirname=  /Users/zl/Documents/dev/nodes/src
```