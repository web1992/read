# closure

闭包的作用：可以访问到一个不是在当前`范围`内的变量

- [closure javascript.info](https://javascript.info/closure)
- [Hoisting](http://www.adequatelygood.com/JavaScript-Scoping-and-Hoisting.html)

This is because JavaScript has function-level scope. This is radically different from the C family. Blocks, such as if statements, do not create a new scope. Only functions create a new scope.

## closure 定义

- [from wikipedia](<https://en.wikipedia.org/wiki/Closure_(computer_programming)>)

Unlike a plain function, a closure allows the function to access those captured variables through the closure's copies of their values or references, even when the function is invoked outside their scope.

## example

- [from mozilla](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Closures)

There is a general programming term “closure”, that developers generally should know.

A closure is a function that remembers its outer variables and can access them. In some languages, that’s not possible, or a function should be written in a special way to make it happen. But as explained above, in JavaScript, all functions are naturally closures (there is only one exclusion, to be covered in The "new Function" syntax).

That is: they automatically remember where they were created using a hidden [[Environment]] property, and all of them can access outer variables.

When on an interview, a frontend developer gets a question about “what’s a closure?”, a valid answer would be a definition of the closure and an explanation that all functions in JavaScript are closures, and maybe few more words about technical details: the [[Environment]] property and how Lexical Environments work.
