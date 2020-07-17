# mysql lock

[https://tech.meituan.com/2014/08/20/innodb-lock.html](https://tech.meituan.com/2014/08/20/innodb-lock.html)

## dead lock

```sql
mysql> select * from t_user;
+----+--------+---------------------+------+
| id | name   | birth_day           | age  |
+----+--------+---------------------+------+
|  1 | test1  | 2020-02-06 02:57:23 |   11 |
|  2 | test2  | 2020-02-06 02:57:23 |    1 |
|  3 | test3  | 2020-02-06 03:10:56 |    0 |
|  4 | test4  | 2020-02-06 03:13:16 |    0 |
|  6 | test5  | 2020-02-06 03:18:24 |    0 |
|  7 | test6  | 2020-02-06 03:23:27 |    0 |
|  8 | test7  | 2020-02-06 03:26:58 |   11 |
|  9 | test7  | 2020-02-06 03:27:12 |   11 |
| 10 | test8  | 2020-02-06 03:27:54 |    0 |
| 11 | test9  | 2020-02-06 03:28:09 |    0 |
| 12 | test10 | 2020-02-06 05:18:17 |    0 |
| 14 | test11 | 2020-02-06 05:18:56 |    0 |
| 16 | test7  | 2020-02-06 05:23:38 |   11 |
| 17 | test7  | 2020-02-06 05:24:43 |   11 |
| 18 | xxx    | 2020-02-06 05:26:24 |   11 |
+----+--------+---------------------+------+
```

| 事务A                                   | 事务B                                                                                  |
| --------------------------------------- | -------------------------------------------------------------------------------------- |
| begin;                                  |
| delete from t_user where id in (17,18); |
|                                         | begin;                                                                                 |
|                                         | delete from t_user where id in (16,17);                                                |
| delete from t_user where id =16;        |
|                                         | ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction |

`show engine innodb status;`

死锁日志：

```sql
------------------------
LATEST DETECTED DEADLOCK
------------------------
2020-02-11 11:52:29 0x7f39641a3700
*** (1) TRANSACTION:
TRANSACTION 1010220, ACTIVE 8 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 3 lock struct(s), heap size 1136, 2 row lock(s), undo log entries 1
MySQL thread id 4, OS thread handle 139884469032704, query id 84 localhost root updating
delete from t_user where id in (16,17)
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 69 page no 3 n bits 88 index PRIMARY of table `web1992`.`t_user` trx id 1010220 lock_mode X locks rec but not gap waiting
Record lock, heap no 6 PHYSICAL RECORD: n_fields 6; compact format; info bits 32
 0: len 8; hex 8000000000000011; asc         ;;
 1: len 6; hex 0000000f6a27; asc     j';;
 2: len 7; hex 40000001cf0663; asc @     c;;
 3: len 5; hex 7465737437; asc test7;;
 4: len 5; hex 99a58c562b; asc    V+;;
 5: len 4; hex 8000000b; asc     ;;

*** (2) TRANSACTION:
TRANSACTION 1010215, ACTIVE 22 sec starting index read
mysql tables in use 1, locked 1
3 lock struct(s), heap size 1136, 3 row lock(s), undo log entries 2
MySQL thread id 2, OS thread handle 139884469303040, query id 85 localhost root updating
delete from t_user where id =16
*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 69 page no 3 n bits 88 index PRIMARY of table `web1992`.`t_user` trx id 1010215 lock_mode X locks rec but not gap
Record lock, heap no 6 PHYSICAL RECORD: n_fields 6; compact format; info bits 32
 0: len 8; hex 8000000000000011; asc         ;;
 1: len 6; hex 0000000f6a27; asc     j';;
 2: len 7; hex 40000001cf0663; asc @     c;;
 3: len 5; hex 7465737437; asc test7;;
 4: len 5; hex 99a58c562b; asc    V+;;
 5: len 4; hex 8000000b; asc     ;;

Record lock, heap no 17 PHYSICAL RECORD: n_fields 6; compact format; info bits 32
 0: len 8; hex 8000000000000012; asc         ;;
 1: len 6; hex 0000000f6a27; asc     j';;
 2: len 7; hex 40000001cf0694; asc @      ;;
 3: len 3; hex 787878; asc xxx;;
 4: len 5; hex 99a58c5698; asc    V ;;
 5: len 4; hex 8000000b; asc     ;;

*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 69 page no 3 n bits 88 index PRIMARY of table `web1992`.`t_user` trx id 1010215 lock_mode X locks rec but not gap waiting
Record lock, heap no 15 PHYSICAL RECORD: n_fields 6; compact format; info bits 32
 0: len 8; hex 8000000000000010; asc         ;;
 1: len 6; hex 0000000f6a2c; asc     j,;;
 2: len 7; hex 230000019804ad; asc #      ;;
 3: len 5; hex 7465737437; asc test7;;
 4: len 5; hex 99a58c55e6; asc    U ;;
 5: len 4; hex 8000000b; asc     ;;

*** WE ROLL BACK TRANSACTION (1)
------------
TRANSACTIONS
------------
Trx id counter 1010222
Purge done for trx's n:o < 1010222 undo n:o < 0 state: running but idle
History list length 10
LIST OF TRANSACTIONS FOR EACH SESSION:
---TRANSACTION 421359746394872, not started
0 lock struct(s), heap size 1136, 0 row lock(s)
---TRANSACTION 1010215, ACTIVE 142 sec
3 lock struct(s), heap size 1136, 3 row lock(s), undo log entries 3
MySQL thread id 2, OS thread handle 139884469303040, query id 85 localhost root
--------
```
