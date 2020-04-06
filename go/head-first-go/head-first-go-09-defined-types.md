# defined types

## DEFINING METHODS

```go
// MyType is receiver parameter
func (m MyType) sayHi(){

}
```

- the  receiver parameter is (pretty much) just another parameter

- The receiver parameter is Go's equivalent to "self" or "this" values in other languages.

- a method is (pretty much) jsut like a function

- pointer receiver parameters

Notice that we didn't have to change the method call at all. When you call a method that requires a pointer receiver on a variable with a nonpointer type, Go will `automatically` `convert` the receiver `to a pointer` for you.

By the way, the code at right breaks a convention: for consistency, all of your type's methods can take `value receivers`, or they can all take `pointer receivers`, but `you should avoid mixing the two`. We're only mixing the two kinds here for demonstration purposes.

## Summary

- Once you've defined a type, you can do a conversion to that type from any value of the underlying type.

```go
Gallons(10.0)
```

- Once a variable's type is defined, values of other types cannot be assigned to that variable, even if they have the same underlying type.

- A defined type supports all the same operators as its `underlying type`. A type based on int, for example, would support +, -, *, /, ==, >, and < operators.

- A defined type can be used in operations together with values of its underlying type:

```go
Gallons(10.) + 2.3
```

To define a method, provide a receiver parameter in `parentheses` before the method name:

```go
func (m MyType) MyMethod() {
}
```

- The receiver parameter can be used within the method block like any other parameter:

```go
func (m MyType) MyMethod() {
fmt.Println("called on", m)
}
```

- You can define additional parameters or return values on a method, just as you would with any other function.

- Defining multiple functions with the same name in the same package is not allowed, even if they have parameters of different types. But you can define multiple
methods with the same name, as long as each is defined on a different type.

- You can only define methods on types that were defined in the same package.

- As with any other parameter, receiver parameters receive a copy of the original value. If your method needs to modify the receiver, you should use a pointer type for the receiver parameter, and modify the value at that pointer.
