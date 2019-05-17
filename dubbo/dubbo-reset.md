# dubbo reset

`dubbo` `reset(http)` 服务集成

`dubbo` 对 `protocl` 进行了抽象，默认的协议是 `DubboProtocol`,是面向 `TCP` 的协议

而 `dubbo reset` 是 `RestProtocol` 是面向 `http` 协议 `RestProtocol` 底层依赖 `jetty`