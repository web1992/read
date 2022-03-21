# Nacos 的配置模型

- 配置项（Configuration Item）
⼀个具体的可配置的参数与其值域，通常以param-key = param-value 的形式存在。例如我们常配置系统的日志输出级别（logLevel = INFO | WARN | ERROR） 就是⼀个配置项。

- 配置集（Configuration Set）
⼀组相关或者不相关的配置项的集合称为配置集。在系统中，⼀个配置文件通常就是⼀个配置集，包含了系统各个方面的配置。例如，⼀个配置集可能包含了数据源、线程池、日志级别等配置项。

- 命名空间（Namespace）
用于进行`租户`粒度的配置隔离。不同的命名空间下，可以存在相同的`Group`或`Data ID` 的配置。`Namespace`的常用场景之⼀是不同环境的配置的区分隔离，例如`开发测试环境`和`生产环境`的资源
（如数据库配置、限流阈值、降级开关）隔离等。如果在没有指定`Namespace`的情况下，默认使用`public`命名空间。

- 配置组（Group）
Nacos 中的⼀组配置集，是配置的维度之⼀。通过⼀个有意义的字符串（如ABTest 中的实验组、对照组）对配置集进行分组，从而区分Data ID 相同的配置集。当您在Nacos 上创建⼀个配置时，
如果未填写配置分组的名称，则配置分组的名称默认采用DEFAULT_GROUP 。配置分组的常见场景：不同的应用或组件使用了相同的配置项，如database_url 配置和MQ_Topic 配置。

- 配置ID（Data ID）
Nacos 中的某个配置集的ID。配置集ID是划分配置的维度之⼀。Data ID 通常用于划分系统的配置集。⼀个系统或者应用可以包含多个配置集，每个配置集都可以被⼀个有意义的名称标识。DataID 尽量保障全局唯⼀，可以参考Nacos Spring Cloud 中的命名规则：

```config
${prefix}-${spring.profiles.active}-${file-extension}
```