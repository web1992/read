# spi

`SPI` 是 `dubbo` 加载实现类的一种方式，给 `Adaptive`（dubbo 自适应）提供了基础。

比如我们想把 `Dubbo` 中默认的线程池从 `fixed` 改成 其他的比如 `limited` 那么只要进行下面的配置就可以实现

而这些背后的支持就是 `Dubbo` 的 `SPI机制` 和 `自适应机制`(序列化协议的切换背后也是SPI提供的支持)

```diff
-- <dubbo:protocol name="dubbo" threadpool="fixed"/>
++ <dubbo:protocol name="dubbo" threadpool="limited"/>
```

请参考: `ExtensionLoader`

- [ExtensionLoader](dubbo-extension-loader.md)
