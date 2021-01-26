# Broker startup

## 启动类

从启动服务的过程，去发现 RocketMQ 提供了那些功能和特性，那些是通用的功能，那些是`特性`。

| Name                             | 描述 |
| -------------------------------- | ---- |
| messageStore                     |
| remotingServer                   |
| fastRemotingServer               |
| fileWatchService                 |
| brokerOuterAPI                   |
| pullRequestHoldService           |
| clientHousekeepingService        |
| filterServerManager              |
| transactionalMessageCheckService |
| registerBrokerAll                |
| brokerStatsManager               |
| brokerFastFailure                |

BrokerController 是启动 Broker 的入口：

BrokerController parseProperties,initialize,start,shutdown

## store config

```sh
ll /Users/zl/store
total 16
-rw-r--r--   1 zl  staff     0B  8 12 09:42 abort
-rw-r--r--   1 zl  staff   4.0K  1 25 20:28 checkpoint
drwxr-xr-x   3 zl  staff    96B  5  1  2020 commitlog
drwxr-xr-x  12 zl  staff   384B  1 25 20:22 config
drwxr-xr-x   3 zl  staff    96B  4 25  2020 consumequeue
drwxr-xr-x   3 zl  staff    96B  1 25 20:28 index
-rw-r--r--   1 zl  staff     4B  1 25 20:28 lock

pwd
/Users/zl/store/config
ll
total 80
-rw-r--r--  1 zl  staff    27B  1 25 20:22 consumerFilter.json
-rw-r--r--  1 zl  staff    27B  1 25 20:22 consumerFilter.json.bak
-rw-r--r--  1 zl  staff   474B  1 25 20:22 consumerOffset.json
-rw-r--r--  1 zl  staff   474B  1 25 20:22 consumerOffset.json.bak
-rw-r--r--  1 zl  staff    21B  1 25 20:22 delayOffset.json
-rw-r--r--  1 zl  staff    21B  1 25 20:22 delayOffset.json.bak
-rw-r--r--  1 zl  staff   2.8K  8 12 09:50 subscriptionGroup.json
-rw-r--r--  1 zl  staff   2.4K  8 12 09:50 subscriptionGroup.json.bak
-rw-r--r--  1 zl  staff   2.7K  8 12 09:50 topics.json
-rw-r--r--  1 zl  staff   2.0K  8 12 09:50 topics.json.bak
```

## broker log

```sh
pwd
/Users/zl/logs/rocketmqlogs
ll
total 598536
-rw-r--r--  1 zl  staff   167K  1 25 20:28 broker.log
-rw-r--r--  1 zl  staff   8.8K  1 25 20:28 broker_default.log
-rw-r--r--  1 zl  staff     0B  1 25 19:59 commercial.log
-rw-r--r--  1 zl  staff     0B  1 25 19:59 filter.log
-rw-r--r--  1 zl  staff     0B  1 25 19:59 lock.log
-rw-r--r--  1 zl  staff    13K  1 25 20:06 namesrv.log
-rw-r--r--  1 zl  staff   454B  1 25 20:04 namesrv_default.log
-rw-r--r--  1 zl  staff     0B  1 25 19:59 protection.log
-rw-r--r--  1 zl  staff    76K  1 25 20:28 remoting.log
-rw-r--r--  1 zl  staff   284M  1 25 20:05 rocketmq_client.log
-rw-r--r--  1 zl  staff   3.0K  1 25 20:06 stats.log
-rw-r--r--  1 zl  staff   5.7M  1 25 20:28 store.log
-rw-r--r--  1 zl  staff     0B  1 25 19:59 storeerror.log
-rw-r--r--  1 zl  staff   9.1K  1 25 20:28 transaction.log
-rw-r--r--  1 zl  staff   158K  1 25 20:22 watermark.log

```
