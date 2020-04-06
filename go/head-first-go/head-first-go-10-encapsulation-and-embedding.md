# encapsulation and embedding

封装和嵌入

## SETTER METHODS

Setter methods are methods used to set fields or other values within a
defined type's underlying value.

SETTER METHODS NEED POINTER RECEIVERS

## Unexported and exported

Unexported variables, struct fields, functions, and methods can still be accessed by exported functions and methods in the same package.

- In Go, data is encapsulated within packages, using unexported package variables or struct fields.
- Unexported variables, struct fields, functions, methods, etc. can still be accessed by exported functions and methods in the same package.
- The practice of ensuring that data is valid before accepting it is known as `"data validation"`.
- A method that is primarily used to set the value of an encapsulated field is known as a "setter method".
Setter methods often include validation logic, to ensure the new value being provided is valid.
- Since setter methods need to modify their receiver, their receiver parameter should have a `pointer type`.
- A method that is primarily used to get the value of an encapsulated field is known as a `"getter method"`.
- Methods defined on an outer struct type live alongside methods promoted from an embedded type.
- An embedded type's unexported methods don't get promoted to the outer type.
