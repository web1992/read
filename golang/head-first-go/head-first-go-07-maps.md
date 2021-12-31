# maps

- When declaring a map variable, you must provide the types for its keys and its values:

```go
var mymap map[string]int
```

- To assign a value to a map, provide the key you want to assign it to in square brackets:

 ```go
 mymap["my key"] = 12
 ```

- To get a value, you provide the key as well: fmt.Println(mymap["my key"]) You can create a map and initialize it with data at the same time using a map literal:
  
```go
map[string]int{"a": 2, "b": 3}
```

- As with arrays and slices, if you access a map key that hasn't been assigned a value, you'll get a zero value back.

- Getting a value from a map can return a second, optional boolean value that indicates whether that value was assigned, or if it represents a default zero value:

```go
value, ok := mymap["c"]
```

- If you only want to test whether a key has had a value assigned, you can ignore the actual value using the _ blank identifier:

```go
_, ok := mymap["c"]
```

- You can delete keys and their corresponding values from a map using the delete builtin function:

```go
delete(mymap, "b")
```

- You can use for ... range loops with maps, much like you can with arrays or slices. You provide one variable that will be assigned each key in turn, and a second variable that will be assigned each value in turn.

```go
for key, value := range mymap {
fmt.Println(key, value)
}
```

- The `for ... range` loop processes map key/value pairs in random order. If you need a specific order, you'll need to handle that yourself.
