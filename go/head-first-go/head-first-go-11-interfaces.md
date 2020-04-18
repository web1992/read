# interfaces

- A `concrete` type specifies not only what its values can do (what methods you can call on them), but also what they are: they specify the underlying type that holds the value's data.
- An `interface` type is an abstract type. Interfaces don't describe what a value is: they don't say what its underlying type is, or how its data is stored. They only describe what a value can do: `what methods it has`.
- An interface definition needs to contain a list of method names, along with any parameters or return values those methods are expected to have.
- To satisfy an interface, a type must have all the methods the interface specifies. Method names, parameter types (or lack thereof), and return value types (or lack thereof) all need to match those defined in the interface.
- A type can have methods in addition to those listed in the interface, but it mustn't
be missing any, or it doesn't satisfy that interface.
- A type can satisfy `multiple` interfaces, and an interface can have multiple types that satisfy it.
- Interface satisfaction is automatic. There is no need to explicitly declare that a concrete type `satisfies` an interface in Go.
- When you have a variable of an interface type, the only methods you can call on it are those defined in the interface.
- If you've assigned a value of a concrete type to a variable with an interface type, you can use a type assertion to get the concrete type value back. Only then can you call methods that are defined on the concrete type (but not the interface.)
- Type assertions return a second bool value that indicates whether the assertion was successful.

```go
car, ok := vehicle.(Car)
```
