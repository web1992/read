# seata

## TCC

- [TCC 简介 AT & TCC https://seata.io/zh-cn/docs/overview/what-is-seata.html](https://seata.io/zh-cn/docs/overview/what-is-seata.html)
- [TCC 概念 http://seata.io/zh-cn/docs/dev/mode/tcc-mode.html](http://seata.io/zh-cn/docs/dev/mode/tcc-mode.html)
- [TCC 源码 http://seata.io/zh-cn/blog/seata-analysis-tcc-modular.html](http://seata.io/zh-cn/blog/seata-analysis-tcc-modular.html)
- [SEATA 快速开始 http://seata.io/zh-cn/blog/seata-quick-start.html](http://seata.io/zh-cn/blog/seata-quick-start.html)
- [TCC 理论及设计实现指南介绍 https://seata.io/zh-cn/blog/tcc-mode-design-principle.html](https://seata.io/zh-cn/blog/tcc-mode-design-principle.html)
- [TCC 适用模型与适用场景分析 https://seata.io/zh-cn/blog/tcc-mode-applicable-scenario-analysis.html](https://seata.io/zh-cn/blog/tcc-mode-applicable-scenario-analysis.html)
- [Seata术语 https://seata.io/zh-cn/docs/overview/terminology.html](https://seata.io/zh-cn/docs/overview/terminology.html)

Seata术语

|                                           | 描述                                                                                           |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------- |
| TC (Transaction Coordinator) - 事务协调者 | 维护全局和分支事务的状态，驱动全局事务提交或回滚。                                             |
| TM (Transaction Manager) - 事务管理器     | 定义全局事务的范围：开始全局事务、提交或回滚全局事务。                                         |
| RM (Resource Manager) - 资源管理器        | 管理分支事务处理的资源，与TC交谈以注册分支事务和报告分支事务的状态，并驱动分支事务提交或回滚。 |
| 分支事物                                  |
| 全局事物                                  |

## 注意事项

任务技术或者框架都不是银弹。不能解决100%的问题，一些特殊的CASE必须小心处理。

- 允许空回滚
- 防悬挂控制
- 幂等&并发控制

## Dubbo + TCC

dubbo 与 tcc 的结合。

1. 暴露 dubbo 接口，并实现三个业务方法，分别是prepar,commit,rollback 三个方法
2. 在 prepare（try业务方法） 接口上面加上TwoPhaseBusinessAction 注解
3. 实现 dubbo 接口。
4. 此 dubbo 接口已经可以被TCC进行管理了（当做分支事物角色）。

## 业务改造注意点

• 业务需要提供预处理接口（订单需新增“下单状态”，“取消状态”）库存需要支持“下单状态”占用库存（释放库存）
• 需要提供“事物状态记录表”,记录此事物是否已经 rollback，支持空回滚等操作。
• prepare 和 rollback 的并发控制（prepare和rollback同时到达，可能存在问题）
• rollback和commit 如果失败，会一直掉，需要设置最大重试次数
• 业务数据监控，比如长时间处于“下单状态”，“预占用状态” 的数据进行监控，进行报警。
• 业务的频繁修改，比如订单修改明细，需要预占用库存（释放库存）。(prepare阶段的修改是否对下游可见，是否需要发送事物消息出来，可以在prepare,commit,rollback 都发消息出来)
• 业务数据从3修改成2，此时事物处于prepare状态，其他业务系统查询到数据是2，此后事物回滚，其他业务系统拿到的数据应该是3才对（除非主动查询，没有办法在拿到3）。此时产生了数据不一致。因此prepare状态的数据不能对其他业务可见。

## 本地事物表

```java
CREATE TABLE `trans_log` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `xid` VARCHAR(96) DEFAULT NULL,
    `biz_id` BIGINT(20) NOT NULL,
    `biz_type` VARCHAR(256) DEFAULT NULL COMMENT '',
    `status` INT(4) DEFAULT NULL COMMENT '-1：删除 1:初始状态，2：已提交，3：已回滚，4:提交中，5：回滚中',
    `version` INT(11) NOT NULL DEFAULT 1 COMMENT '版本号',
    `gmt_create` DATETIME DEFAULT NULL,
    `gmt_modified` DATETIME DEFAULT NULL,
    PRIMARY KEY (`id`)
)  ENGINE=INNODB AUTO_INCREMENT=1 DEFAULT CHARSET=UTF8 COMMENT '本地事物日志表';
```
