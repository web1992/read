# structs

slices and maps hold values fo obe type,structs atre built out of values of many type

A struct (short for "structure") is a value that is constructed out of other values of
many different types

```go
// declare struct variables
var myStruct struct {
  number float64
  word   string
  oggle bool
}

fmt.Printf("%#v\n", myStruct)

myStruct.number = 3.14
fmt.Println("number is ", myStruct.number)
```

## DEFINED TYPES AND STRUCTS

```go
type myType struct {
    name string
}
```

## USING DEFINED TYPES WITH FUNCTIONS

type struct 当做参数和返回值的时候，尽量使用指针，这样可以避免数据copy

- You can declare a variable with a struct type. To specify a struct type, use the `struct` keyword, followed by a list of field names and types within curly braces.

```go
var myStruct struct {
field1 string
field2 int
}
```

- Writing struct types repeatedly can get tedious, so it's usually best to define a type with an underlying struct type. Then the defined type can be used for variables, function parameters or return values, etc.

```go
type myType struct {
field1 string
}
var myVar myType
```

- Struct fields are accessed via the `dot` operator.

```go
myVar.field1 = "value"
fmt.Println(myVar.field1)
```

- If a function needs to modify a struct or if a struct is `large`, it should be passed to the function as a `pointer`.

- Types will only be exported from the package they're defined in if their `name` begins with a `capital letter`.

- Likewise, struct fields will not be accessible outside their package unless their name is capitalized. Struct literals let you create a struct and set its fields at the same time.

```go
myVar := myType{field1: "value"}
```

- Adding a struct field with no name, only a type, defines an `anonymous` field.

- An inner struct that is added as part of an outer struct using an anonymous field is said to be embedded within the outer struct.

- You can access the fields of an `embedded` struct as if they belong to the outer struct.
