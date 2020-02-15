# mybatis

`mybatis` 源码学习

## index

- [x] [mybatis-sql-session.md](mybatis-sql-session.md)
- [x] [mybatis-sql-session-factory-bean.md](mybatis-sql-session-factory-bean.md)
- [x] [mybatis-sql-session-template.md](mybatis-sql-session-template.md)
- [x] [mybatis-executor.md](mybatis-executor.md)
- [x] [mybatis-cache.md](mybatis-cache.md)
- [x] [mybatis-interceptor.md](mybatis-interceptor.md)
- [x] [mybatis-mapper-proxy.md](mybatis-mapper-proxy.md)

- [x] [mybatis-mapper-scanner-configurer.md](mybatis-mapper-scanner-configurer.md)
- [ ] [mybatis-pooled-data-source.md](mybatis-pooled-data-source.md)
- [ ] [mybatis-spring.md](mybatis-spring.md)
- [ ] [mybatis-configuration.md](mybatis-configuration.md)
- [ ] [mybatis-statement-handler.md](mybatis-statement-handler.md)
- [ ] [mybatis-xml-statement-builder.md](mybatis-xml-statement-builder.md)
- [x] [mybatis-mapper-method.md](mybatis-mapper-method.md)
- [ ] [mybatis-mapped-statement.md](mybatis-mapped-statement.md)
- [ ] [mybatis-result-set-handler.md](mybatis-result-set-handler.md)
- [ ] [mybatis-type-handler.md](mybatis-type-handler.md)
- [x] [mybatis-tx.md](mybatis-tx.md)
- [ ] [mybatis-bound-sql.md](mybatis-bound-sql.md)
- [ ] [mybatis-key-generator.md](mybatis-key-generator.md)
- [ ] [mybatis-mapper-factory-bean.md](mybatis-mapper-factory-bean.md)
- [ ] [mybstis-xml-config-builder.md](mybstis-xml-config-builder.md)

## mybatis 代码执行图

![exe](./images/mybatis-exe.draw.png)

## mybatis 设计模式

mybatis 中使用的设计模式：

| 设计模式     | 实例类                                           |
| ------------ | ------------------------------------------------ |
| 抽象工厂模式 | `TransactionFactory`                             |
| 装饰器模式   | `CachingExecutor`,`SimpleExecutor`,`Cache`       |
| 代理         | `MapperProxy`,`Interceptor`,`SqlSessionTemplate` |

## Link

- [http://www.mybatis.org/mybatis-3/getting-started.html](http://www.mybatis.org/mybatis-3/getting-started.html)
