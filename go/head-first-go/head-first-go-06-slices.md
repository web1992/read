# slices

- change the underlying `array` ,change the `slice`

- A slice variable is declared just like an array variable, except the length is omitted: var myslice []int
- For the most part, code for working with slices is identical to code that works with arrays. This includes: accessing elements, using zero values, passing slices to the len function, and for ... range loops.
- A slice literal looks just like an array literal, except the length is omitted: []int{1, 7, 10}
- You can get a slice that contains elements i through j - 1 of an array or slice using the slice operator: s[i:j]
- The os.Args package variable contains a slice of strings with the commandline arguments the current program was run with.
- A variadic function is one that can be called with a varying number of arguments.
- To declare a variadic function, place an ellipsis (...) before the type of the last parameter in the function declaration. That parameter will then receive all the variadic arguments as a slice.
- When calling a variadic function, you can use a slice in place of the variadic arguments by typing an ellipsis after the slice: inRange(1, 10, myslice...)