# arthas

## start

```shell
java  -jar math-game.jar

# 不建议使用 arthas-boot.jar 会有各种问题

java  -jar arthas-boot.jar

as.bat <pid>

watch io.netty.example.http.helloworld.HttpHelloWorldServerHandler channelRead0

trace io.netty.example.http.helloworld.HttpHelloWorldServerHandler channelRead0 -n 2

stack io.netty.example.http.helloworld.HttpHelloWorldServerHandler channelRead0 -n 2
stack io.netty.example.http.helloworld.HttpHelloWorldServerHandler channelRead0 -n 2
```

## web console

- http://127.0.0.1:8563/

## Kill

```shell
taskkill /PID 14280 /F
```

jad io.netty.example.localecho.LocalEchoClientHandler