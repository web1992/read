# Protocol

`Protocol`中主要有两个方法：`export`和`refer`

`Protocol`的两个主要的实现类是`DubboProtocol`和`RegistryProtocol`

`export` 主要是服务器相关的业务，如启用一个 Netty 服务，并暴露服务

`refer` 主要是客户端相关的业务，如注册，订阅一个服务

`destroy` 负责服务的取消注册

## DubboProtocol

## RegistryProtocol