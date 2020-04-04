# structs

slices and maps hold values fo obe type,structs atre built out of values of many type

A struct (short for "structure") is a value that is constructed out of other values of
many different types

```golang
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

```golang
type myType struct {
    name string
}
```

## USING DEFINED TYPES WITH FUNCTIONS

type struct 当做参数和返回值的时候，尽量使用指针，这样可以避免数据copy
