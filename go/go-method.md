# method

- 方法变量

## 方法变量

```go
type Rocket struct { /*.....*/}
func (r Rocket) Launch(){/*.....*/}

r := new(Rocket)
time.AfterFunc(10 * time.Second,func(){ r.Launch() })

// 简化
time.AfterFunc(10 * time.Second,r.Launch)

```
