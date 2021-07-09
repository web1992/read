# redis

./redis-cli -h 127.0.0.1 -p 7001 -a 123456 cluster addslots {0..5461}
./redis-cli -h 127.0.0.1 -p 7002 -a 123456 cluster addslots {5462..10922}
./redis-cli -h 127.0.0.1 -p 7003 -a 123456 cluster addslots {10923..16383}