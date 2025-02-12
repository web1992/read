# arthas

## start

```shell
D:\Software\Java\bin\java  -jar math-game.jar

D:\Software\Java\bin\java  -jar arthas-boot.jar

D:\Software\Java\bin\jps


watch io.netty.example.http.helloworld.HttpHelloWorldServerHandler channelRead0

trace io.netty.example.http.helloworld.HttpHelloWorldServerHandler channelRead0 -n 2
```


## Kill

```shell
taskkill /PID 14280 /F
```

jad io.netty.example.localecho.LocalEchoClientHandler