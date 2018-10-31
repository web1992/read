# == and ===

- [== and ===](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Comparison_Operators)

JavaScript has both strict and type–converting comparisons. A strict comparison (e.g., ===) is only true if the operands are of the same type and the contents match. The more commonly-used abstract comparison (e.g. ==) converts the operands to the same type before making the comparison. For relational abstract comparisons (e.g., <=), the operands are first converted to primitives, then to the same type, before comparison.

Strings are compared based on standard lexicographical ordering, using Unicode values.

- == 如果类型不同会进行类型转化
- == 如果是对象直接的比较，指向同一对象才是`true`
