# interface

go 中的接口是隐式的，对于具体的类型，无需声明了它实现了那些接口，只需要提供接口所必须的方法即可。

这中设计让你无需改变已有类型的变量的实现，就可以为这些类型创建新的接口，对于那些不能修改的包的类型，特别有用。

## 鸭子类型

> If it looks like a duck, swims like a duck, and quacks like a duck, then it probably is a duck.

- 接口即约定
- 可取代性
- 嵌入式接口
- 空接口类型
- 接口的动态类型和动态值

## demo

- fmt.Stringger
- io.Writer
- sort.Interface
- http.Handler

## Links

- [https://mp.weixin.qq.com/s/XKirIaGmyBAwpFKo9Yekxw](https://mp.weixin.qq.com/s/XKirIaGmyBAwpFKo9Yekxw)