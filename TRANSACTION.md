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


