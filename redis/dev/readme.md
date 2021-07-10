# dev

- redis-7001.conf
- redis-7002.conf
- redis-7003.conf

```conf
# redis-7001.conf
bind 0.0.0.0
port 7001
pidfile /var/run/redis_7001.pid
daemonize yes
cluster-enabled yes
cluster-node-timeout 15000
cluster-config-file nodes-7001.conf
masterauth 123456
requirepass 123456
# redis-7002.conf
bind 0.0.0.0
port 7002
pidfile /var/run/redis_7002.pid
daemonize yes
cluster-enabled yes
cluster-node-timeout 15000
cluster-config-file nodes-7002.conf
masterauth 123456
requirepass 123456
# redis-7003.conf
bind 0.0.0.0
port 7003
pidfile /var/run/redis_7003.pid
daemonize yes
cluster-enabled yes
cluster-node-timeout 15000
cluster-config-file nodes-7003.conf
masterauth 123456
requirepass 123456
```

- sentinel-26379.conf
- sentinel-26380.conf
- sentinel-26381.conf

```conf
# sentinel-26379.conf
# sentinel-26380.conf
# sentinel-26381.conf

port 26379
bind 0.0.0.0
daemonize yes
logfile "/root/redis/redis-6.0.6/logs/26379-sentinel.log"
sentinel announce-ip 81.68.100.22
sentinel announce-port 26379

sentinel deny-scripts-reconfig yes
sentinel monitor mymaster 81.68.100.22 7001 1
sentinel down-after-milliseconds mymaster 60000
sentinel auth-pass mymaster 123456
```
