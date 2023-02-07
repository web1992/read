# Spring Cloud Config


## 配置

- spring.cloud.config.uri
- spring.cloud.config.failFast=true

Spring Cloud Config 的客户端在启动的时候，默认会从工程的`classpath`中加载配置信息并启动应用。只有当我们配置 pring.cloud.config.uri 的时候， 客户端应用才会尝试连接Spring Cloud Config的服务端来获取远程配置信息并初始化Spring环境配置。 同时， 我们必须将该参数配置在bootstrap.properties、环境变量或是其他优先级高于应用Jar包内的配置信息中，才能正确加载到远程配置。若不指定 pring.cloud.config.uri 参数的话， Spring Cloud Config 的客户端会默认尝试连接http://localhost:8888。