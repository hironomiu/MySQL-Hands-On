# トランザクション(ロック、分離レベル)

## 準備
ターミナルは二つ起動すること以後ターミナル1、ターミナル2と呼ぶ

Master,Slave構成の場合はMasterのみで作業を行います

### ターミナル1
tran_testデータベース、transaction_testテーブルを作成


```
# mysql
mysql> prompt term-1 > ;
PROMPT set to 'term-1 > '
term-1 > create database tran_test;
term-1 > use tran_test;
term-1 > create table transaction_test ( id int(8) not null AUTO_INCREMENT, col1 char(1) not null, col2 int(8), rec_date datetime, PRIMARY KEY (id), key (col2), key (rec_date));
term-1 > insert into transaction_test (col1, col2,rec_date) values ( 'b' ,35,'2010-04-07'),( 'a' ,40,'2010-04-08'),( 'c' ,20,'2010-04-09'),( 'b' ,25,'2010-04-10'),( 'a' ,50,'2010-04-11'),( 'c' ,10,'2010-04-12'),( 'b' ,45,'2010-04-13'),( 'a' ,15,'2010-04-14'),( 'c' ,30,'2010-04-15');
```

### ターミナル2
transaction_testテーブルが参照できること

```
# mysql
mysql> prompt term-2 > ;
PROMPT set to 'term-2 > '
term-2 > use tran_test;
term-2 > show tables like 'transaction_test';
+----------------------------+
| Tables_in_test (tran_test) |
+----------------------------+
| transaction_test           |
+----------------------------+
1 row in set (0.00 sec)
```


## SELECT FOR UPDATE(1)
ターミナル1,2ともにautocommitはオフに設定

```
term-1 > set autocommit = 0;
term-1 > select @@autocommit;
+--------------+
| @@autocommit |
+--------------+
|            0 |
+--------------+
1 row in set (0.00 sec)
```

### ターミナル1
```
term-1 > select * from transaction_test for update;
+----+------+------+---------------------+
| id | col1 | col2 | rec_date            |
+----+------+------+---------------------+
|  1 | b    |   35 | 2010-04-07 00:00:00 |
|  2 | a    |   40 | 2010-04-08 00:00:00 |
|  3 | c    |   20 | 2010-04-09 00:00:00 |
|  4 | b    |   25 | 2010-04-10 00:00:00 |
|  5 | a    |   50 | 2010-04-11 00:00:00 |
|  6 | c    |   10 | 2010-04-12 00:00:00 |
|  7 | b    |   45 | 2010-04-13 00:00:00 |
|  8 | a    |   15 | 2010-04-14 00:00:00 |
|  9 | c    |   30 | 2010-04-15 00:00:00 |
+----+------+------+---------------------+
9 rows in set (0.00 sec)
```

### ターミナル2
エラーとなること（前段で確認したinnodb_lock_wait_timeoutの時間分待つ）

```
term-2 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,100,'2016-02-01');
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
```

### ターミナル1,2ともに
```
term-1 > rollback;
```

## SELECT FOR UPDATE(2)

### ターミナル1
```
term-1 > select * from transaction_test where id = 4 for update;

+----+------+------+---------------------+
| id | col1 | col2 | rec_date            |
+----+------+------+---------------------+
|  4 | b    |   25 | 2010-04-10 00:00:00 |
+----+------+------+---------------------+
1 row in set (0.00 sec)
```

### ターミナル2
エラーとならないこと

```
term-2 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,100,'2016-02-01');
Query OK, 1 row affected (0.00 sec)
```

エラーとなること

```
term-2 > select * from transaction_test where id = 4 for update;
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
```

### Question

----

SELECT FOR UPDATE(1)(2)でターミナル2の`insert into transaction_test (col1, col2,rec_date) values ( 'a' ,100,'2016-02-01');`の成否の理由を答えよ

----


## 楽観ロック
ターミナル1,2ともにautocommitはオフに設定

```
term-1 > set autocommit = 0;
term-1 > select @@autocommit;
+--------------+
| @@autocommit |
+--------------+
|            0 |
+--------------+
1 row in set (0.00 sec)
```

### ターミナル1,2ともに

```
term-1 > select id,col1,col2 from transaction_test where col1 = 'a' limit 1;
+----+------+------+
| id | col1 | col2 |
+----+------+------+
|  2 | a    |   40 |
+----+------+------+
1 row in set (0.00 sec)
```

### ターミナル1
**[重要]Rows matched: 1  Changed: 1に注目**

col1がaからzに変わっていること（更新の成功）

```
mysql> update transaction_test set col1 = 'z' , col2 = col2 + 1 where id = 2 and col2 = 40;
Query OK, 1 row affected (0.01 sec)
Rows matched: 1  Changed: 1  Warnings: 0

term-1 > select id,col1,col2 from transaction_test where id = 2;
+----+------+------+
| id | col1 | col2 |
+----+------+------+
|  2 | z    |   41 |
+----+------+------+
1 row in set (0.00 sec)

mysql> commit;
```


### ターミナル2
**[重要]Rows matched: 0  Changed: 0に注目**

commit後col1がターミナル1で更新されたzになっていることを確認(ターミナル2の更新失敗)

```
mysql> update transaction_test set col1 = 'q' , col2 = 41 where id = 2 and col2 = 40;
Query OK, 0 rows affected (0.00 sec)
Rows matched: 0  Changed: 0  Warnings: 0

term-2 > select id,col1,col2 from transaction_test where id = 2;
+----+------+------+
| id | col1 | col2 |
+----+------+------+
|  2 | a    |   40 |
+----+------+------+
1 row in set (0.00 sec)

term-2 > commit;
Query OK, 0 rows affected (0.00 sec)

term-2 > select id,col1,col2 from transaction_test where id = 2;
+----+------+------+
| id | col1 | col2 |
+----+------+------+
|  2 | z    |   41 |
+----+------+------+
1 row in set (0.00 sec)
```

### Question

----

ターミナル2のcommit前後で`select id,col1,col2 from transaction_test where id = 2;`の内容が違う理由を答えよ

----

## 分離レベル(ダーティリード)
ターミナル1、2ともに分離レベルがread uncommitted、autocommitがオフであること

```
term-1 > set session transaction isolation level read uncommitted;

term-1 > select @@tx_isolation;
+------------------+
| @@tx_isolation   |
+------------------+
| READ-UNCOMMITTED |
+------------------+
1 row in set (0.00 sec)

term-1 > set autocommit = 0;

term-1 > select @@autocommit;
+--------------+
| @@autocommit |
+--------------+
|            0 |
+--------------+
1 row in set (0.00 sec)
```

### ターミナル1(準備)
データを再セットアップ

```
term-1 > truncate table transaction_test;
term-1 > insert into transaction_test (col1, col2,rec_date) values ( 'b' ,35,'2010-04-07'),( 'a' ,40,'2010-04-08'),( 'c' ,20,'2010-04-09'),( 'b' ,25,'2010-04-10'),( 'a' ,50,'2010-04-11'),( 'c' ,10,'2010-04-12'),( 'b' ,45,'2010-04-13'),( 'a' ,15,'2010-04-14'),( 'c' ,30,'2010-04-15');
```

### ターミナル1
```
term-1 > start transaction;

term-1 > update transaction_test set col2=col2+10 where id = 1;

term-1 > select col2 from transaction_test where id = 1;
+------+
| col2 |
+------+
|   45 |
+------+
1 row in set (0.00 sec)
```

### ターミナル2
未commitのデータが見えること

```
term-2 > start transaction;

term-2 > select col2 from transaction_test where id = 1;
+------+
| col2 |
+------+
|   45 |
+------+
1 row in set (0.00 sec)
```

### ターミナル1
```
term-1 > rollback;

term-1 > select col2 from transaction_test where id = 1;
+------+
| col2 |
+------+
|   35 |
+------+
1 row in set (0.00 sec)
```

### ターミナル2
rollback後のデータが見えること

```
term-2 > select col2 from transaction_test where id = 1;
+------+
| col2 |
+------+
|   35 |
+------+
1 row in set (0.00 sec)
```

## 分離レベル(反復不能読込み)

ターミナル1、2ともに**MySQLログインをし直して**、分離レベルread committed、autocommitオフに設定

```
mysql> prompt term-1 > ;
term-1 > set session transaction isolation level read committed;

term-1 > select @@tx_isolation;
+----------------+
| @@tx_isolation |
+----------------+
| READ-COMMITTED |
+----------------+
1 row in set (0.00 sec)

term-1 > set autocommit = 0;

term-1 > select @@autocommit;
+--------------+
| @@autocommit |
+--------------+
|            0 |
+--------------+
1 row in set (0.00 sec)
```

### ターミナル1

```
term-1 > start transaction;
Query OK, 0 rows affected (0.00 sec)
```

### ターミナル2
```
term-2 > start transaction;

term-2 > select col2 from transaction_test where id = 1;
+------+
| col2 |
+------+
|   35 |
+------+
1 row in set (0.00 sec)
```

### ターミナル1
```
term-1 > update transaction_test set col2 = col2 + 10 where id = 1;
```

### ターミナル2
```
term-2 > select col2 from transaction_test where id = 1;
+------+
| col2 |
+------+
|   35 |
+------+
1 row in set (0.00 sec)
```

### ターミナル1
```
term-1 > commit;

```

### ターミナル2
```
term-2 > select col2 from transaction_test where id = 1;
+------+
| col2 |
+------+
|   45 |
+------+
1 row in set (0.00 sec)
```

## 分離レベル(ファントムリード READ COMMITTED)


### ターミナル1
**MySQLログインをし直して**、分離レベルREPEATABLE-READ(デフォルト)に設定

```
mysql> prompt term-1 > ;

term-1 > select @@tx_isolation;
+-----------------+
| @@tx_isolation  |
+-----------------+
| REPEATABLE-READ |
+-----------------+
1 row in set (0.00 sec)
```

### ターミナル2
**MySQLログインをし直して**、分離レベルREAD COMMITTEDに設定

```
mysql> prompt term-2 > ;
term-2 > set session transaction isolation level read committed;

term-2 > select @@tx_isolation;
+----------------+
| @@tx_isolation |
+----------------+
| READ-COMMITTED |
+----------------+
1 row in set (0.00 sec)
```

### ターミナル1,2共通
autocommitオフに設定,tran_testに遷移

```
term-1 > set autocommit = 0;

term-1 > select @@autocommit;
+--------------+
| @@autocommit |
+--------------+
|            0 |
+--------------+
1 row in set (0.00 sec)

term-1 > use tran_test
```

### ターミナル2
```
term-2 > start transaction;

term-2 > select id from transaction_test;
+----+
| id |
+----+
|  6 |
|  8 |
|  3 |
|  4 |
|  9 |
|  2 |
|  1 |
|  7 |
|  5 |
+----+
9 rows in set (0.00 sec)



term-2 > select act_code from account;
+----------+
| act_code |
+----------+
|      100 |
|      200 |
|      300 |
+----------+
3 rows in set (0.00 sec)
```

### ターミナル1
```
term-1 > start transaction;

term-1 > select id from transaction_test;
+----+
| id |
+----+
|  6 |
|  8 |
|  3 |
|  4 |
|  9 |
|  2 |
|  1 |
|  7 |
|  5 |
+----+
9 rows in set (0.00 sec)

term-1 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,100,'2016-02-01');

term-1 > commit;

term-1 > select id from transaction_test;
+----+
| id |
+----+
|  6 |
|  8 |
|  3 |
|  4 |
|  9 |
|  2 |
|  1 |
|  7 |
|  5 |
| 10 |
+----+
10 rows in set (0.00 sec)
```

### ターミナル2
10が存在すること

```
term-2 > select id from transaction_test;
+----+
| id |
+----+
|  6 |
|  8 |
|  3 |
|  4 |
|  9 |
|  2 |
|  1 |
|  7 |
|  5 |
| 10 |
+----+
10 rows in set (0.00 sec)
```

## デッドロック
ターミナル1、2ともに**MySQLログインをし直して**、分離レベルREPEATABLE-READ(デフォルト)、autocommitオフに設定

```
mysql> prompt term-1 > ;

term-1 > select @@tx_isolation;
+-----------------+
| @@tx_isolation  |
+-----------------+
| REPEATABLE-READ |
+-----------------+
1 row in set (0.00 sec)

term-1 > set autocommit = 0;

term-1 > select @@autocommit;
+--------------+
| @@autocommit |
+--------------+
|            0 |
+--------------+
1 row in set (0.00 sec)

term-1 > use tran_test
```

### ターミナル1(準備)
データを再セットアップ

```
term-1 > truncate table transaction_test;
term-1 > insert into transaction_test (col1, col2,rec_date) values ( 'b' ,35,'2010-04-07'),( 'a' ,40,'2010-04-08'),( 'c' ,20,'2010-04-09'),( 'b' ,25,'2010-04-10'),( 'a' ,50,'2010-04-11'),( 'c' ,10,'2010-04-12'),( 'b' ,45,'2010-04-13'),( 'a' ,15,'2010-04-14'),( 'c' ,30,'2010-04-15');
```

### ターミナル1
```
term-1 > start transaction;
Query OK, 0 rows affected (0.00 sec)

term-1 > select * from transaction_test;
+----+------+------+---------------------+
| id | col1 | col2 | rec_date            |
+----+------+------+---------------------+
|  1 | b    |   35 | 2010-04-07 00:00:00 |
|  2 | a    |   40 | 2010-04-08 00:00:00 |
|  3 | c    |   20 | 2010-04-09 00:00:00 |
|  4 | b    |   25 | 2010-04-10 00:00:00 |
|  5 | a    |   50 | 2010-04-11 00:00:00 |
|  6 | c    |   10 | 2010-04-12 00:00:00 |
|  7 | b    |   45 | 2010-04-13 00:00:00 |
|  8 | a    |   15 | 2010-04-14 00:00:00 |
|  9 | c    |   30 | 2010-04-15 00:00:00 |
+----+------+------+---------------------+
9 rows in set (0.00 sec)

term-1 > update transaction_test set col2 = 50 where id = 2;
Rows matched: 1  Changed: 1  Warnings: 0
Query OK, 1 row affected (0.00 sec)
```

### ターミナル2
```
term-2 > start transaction;
Query OK, 0 rows affected (0.00 sec)

term-2 > select * from transaction_test;
+----+------+------+---------------------+
| id | col1 | col2 | rec_date            |
+----+------+------+---------------------+
|  1 | b    |   35 | 2010-04-07 00:00:00 |
|  2 | a    |   40 | 2010-04-08 00:00:00 |
|  3 | c    |   20 | 2010-04-09 00:00:00 |
|  4 | b    |   25 | 2010-04-10 00:00:00 |
|  5 | a    |   50 | 2010-04-11 00:00:00 |
|  6 | c    |   10 | 2010-04-12 00:00:00 |
|  7 | b    |   45 | 2010-04-13 00:00:00 |
|  8 | a    |   15 | 2010-04-14 00:00:00 |
|  9 | c    |   30 | 2010-04-15 00:00:00 |
+----+------+------+---------------------+
9 rows in set (0.00 sec)

term-2 > update transaction_test set col2 = 20 where id = 6;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0
```

### ターミナル1
応答が返らないこと(そのまま次を行う)

```
term-1 > update transaction_test set col2 = 40 where id = 6;
```

### ターミナル2
```
term-2 > update transaction_test set col2 = 30 where id = 2;
ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
```

### ターミナル1
応答が返ること

```
Query OK, 1 row affected (10.64 sec)
Rows matched: 1  Changed: 1  Warnings: 0
```

デッドロックの確認

```
term-1 > show engine innodb status\G
*************************** 1. row ***************************
  Type: InnoDB
  Name:
Status:
=====================================
2016-02-09 15:08:40 7fae0f2f2700 INNODB MONITOR OUTPUT
=====================================
Per second averages calculated from the last 24 seconds
-----------------
BACKGROUND THREAD
-----------------
srv_master_thread loops: 6 srv_active, 0 srv_shutdown, 4159 srv_idle
srv_master_thread log flush and writes: 4165
----------
SEMAPHORES
----------
OS WAIT ARRAY INFO: reservation count 11
OS WAIT ARRAY INFO: signal count 11
Mutex spin waits 0, rounds 0, OS waits 0
RW-shared spins 11, rounds 360, OS waits 11
RW-excl spins 0, rounds 0, OS waits 0
Spin rounds per wait: 0.00 mutex, 32.73 RW-shared, 0.00 RW-excl
------------------------
LATEST DETECTED DEADLOCK
------------------------
2016-02-09 14:59:20 7fae0f2b1700
*** (1) TRANSACTION:
TRANSACTION 13590, ACTIVE 171 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 3 lock struct(s), heap size 360, 2 row lock(s), undo log entries 1
MySQL thread id 8, OS thread handle 0x7fae0f2f2700, query id 80 localhost root updating
update transaction_test set col2 = 40 where id = 6
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 18 page no 3 n bits 80 index `PRIMARY` of table `tran_test`.`transaction_test` trx id 13590 lock_mode X locks rec but not gap waiting
Record lock, heap no 7 PHYSICAL RECORD: n_fields 6; compact format; info bits 0
 0: len 4; hex 80000006; asc     ;;
 1: len 6; hex 000000003517; asc     5 ;;
 2: len 7; hex 120000018d0c85; asc        ;;
 3: len 1; hex 63; asc c;;
 4: len 4; hex 80000014; asc     ;;
 5: len 5; hex 9985980000; asc      ;;

*** (2) TRANSACTION:
TRANSACTION 13591, ACTIVE 53 sec starting index read
mysql tables in use 1, locked 1
3 lock struct(s), heap size 360, 2 row lock(s), undo log entries 1
MySQL thread id 9, OS thread handle 0x7fae0f2b1700, query id 81 localhost root updating
update transaction_test set col2 = 30 where id = 2
*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 18 page no 3 n bits 80 index `PRIMARY` of table `tran_test`.`transaction_test` trx id 13591 lock_mode X locks rec but not gap
Record lock, heap no 7 PHYSICAL RECORD: n_fields 6; compact format; info bits 0
 0: len 4; hex 80000006; asc     ;;
 1: len 6; hex 000000003517; asc     5 ;;
 2: len 7; hex 120000018d0c85; asc        ;;
 3: len 1; hex 63; asc c;;
 4: len 4; hex 80000014; asc     ;;
 5: len 5; hex 9985980000; asc      ;;

*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 18 page no 3 n bits 80 index `PRIMARY` of table `tran_test`.`transaction_test` trx id 13591 lock_mode X locks rec but not gap waiting
Record lock, heap no 3 PHYSICAL RECORD: n_fields 6; compact format; info bits 0
 0: len 4; hex 80000002; asc     ;;
 1: len 6; hex 000000003516; asc     5 ;;
 2: len 7; hex 11000001b00556; asc       V;;
 3: len 1; hex 61; asc a;;
 4: len 4; hex 80000032; asc    2;;
 5: len 5; hex 9985900000; asc      ;;

*** WE ROLL BACK TRANSACTION (2)
------------
TRANSACTIONS
------------
Trx id counter 13597
Purge done for trx's n:o < 13593 undo n:o < 0 state: running but idle
History list length 184
LIST OF TRANSACTIONS FOR EACH SESSION:
---TRANSACTION 13591, not started
MySQL thread id 9, OS thread handle 0x7fae0f2b1700, query id 81 localhost root cleaning up
---TRANSACTION 13590, ACTIVE 731 sec
3 lock struct(s), heap size 360, 2 row lock(s), undo log entries 2
MySQL thread id 8, OS thread handle 0x7fae0f2f2700, query id 82 localhost root init
show engine innodb status
Trx read view will not see trx with id >= 13591, sees < 13591
--------
FILE I/O
--------
I/O thread 0 state: waiting for completed aio requests (insert buffer thread)
I/O thread 1 state: waiting for completed aio requests (log thread)
I/O thread 2 state: waiting for completed aio requests (read thread)
I/O thread 3 state: waiting for completed aio requests (read thread)
I/O thread 4 state: waiting for completed aio requests (read thread)
I/O thread 5 state: waiting for completed aio requests (read thread)
I/O thread 6 state: waiting for completed aio requests (write thread)
I/O thread 7 state: waiting for completed aio requests (write thread)
I/O thread 8 state: waiting for completed aio requests (write thread)
I/O thread 9 state: waiting for completed aio requests (write thread)
Pending normal aio reads: 0 [0, 0, 0, 0] , aio writes: 0 [0, 0, 0, 0] ,
 ibuf aio reads: 0, log i/o's: 0, sync i/o's: 0
Pending flushes (fsync) log: 0; buffer pool: 0
371 OS file reads, 95 OS file writes, 58 OS fsyncs
0.00 reads/s, 0 avg bytes/read, 0.00 writes/s, 0.00 fsyncs/s
-------------------------------------
INSERT BUFFER AND ADAPTIVE HASH INDEX
-------------------------------------
Ibuf: size 1, free list len 554, seg size 556, 0 merges
merged operations:
 insert 0, delete mark 0, delete 0
discarded operations:
 insert 0, delete mark 0, delete 0
Hash table size 276671, node heap has 1 buffer(s)
0.00 hash searches/s, 0.00 non-hash searches/s
---
LOG
---
Log sequence number 11540922179
Log flushed up to   11540922179
Pages flushed up to 11540922179
Last checkpoint at  11540922179
0 pending log writes, 0 pending chkp writes
30 log i/o's done, 0.00 log i/o's/second
----------------------
BUFFER POOL AND MEMORY
----------------------
Total memory allocated 137363456; in additional pool allocated 0
Dictionary memory allocated 73346
Buffer pool size   8191
Free buffers       7875
Database pages     315
Old database pages 0
Modified db pages  0
Pending reads 0
Pending writes: LRU 0, flush list 0, single page 0
Pages made young 0, not young 0
0.00 youngs/s, 0.00 non-youngs/s
Pages read 313, created 6, written 57
0.00 reads/s, 0.00 creates/s, 0.00 writes/s
No buffer pool page gets since the last printout
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
LRU len: 315, unzip_LRU len: 0
I/O sum[0]:cur[0], unzip sum[0]:cur[0]
--------------
ROW OPERATIONS
--------------
0 queries inside InnoDB, 0 queries in queue
1 read views open inside InnoDB
Main thread process no. 2087, id 140385515489024, state: sleeping
Number of rows inserted 10, updated 3, deleted 0, read 72
0.00 inserts/s, 0.00 updates/s, 0.00 deletes/s, 0.00 reads/s
----------------------------
END OF INNODB MONITOR OUTPUT
============================

1 row in set (0.00 sec)
```

