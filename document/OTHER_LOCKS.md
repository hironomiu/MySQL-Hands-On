# その他のロック周り

## 準備
ターミナルは二つ起動すること以後ターミナル1、ターミナル2と呼ぶ

Master,Slave構成の場合はMasterのみで作業を行います

### ターミナル1
tran_testデータベース、transaction_testテーブルを作成(データベースが存在する場合はSkipする、テーブルは再作成する)


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


### ターミナル1,2共通
ターミナル1,2ともにautocommitはオフ、REPEATABLE-READに設定

```
term-1 > set autocommit = 0;
term-1 > select @@autocommit;
+--------------+
| @@autocommit |
+--------------+
|            0 |
+--------------+
1 row in set (0.00 sec)

term-1 > select @@tx_isolation;
+-----------------+
| @@tx_isolation  |
+-----------------+
| REPEATABLE-READ |
+-----------------+
1 row in set (0.00 sec)
```

## メタデータロック
[参考情報1](https://dev.mysql.com/doc/refman/5.6/ja/metadata-locking.html)

[参考情報2](http://bugs.mysql.com/bug.php?id=60563)

### 準備
`long_query_time = 0.5`の次の行に追記し設定後再起動

```
# vi /etc/my.cnf
+ lock_wait_timeout = 60

# service mysql restart
```


### ターミナル1


```
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
```
### ターミナル2
応答が返らず待ち状態になること

```
term-2 > alter table transaction_test add column hoge varchar(10);
```

### ターミナル1
`Waiting for table metadata lock`を確認

```
> show processlist;
+----+------+-----------+-----------+---------+------+---------------------------------+----------------------------------------------------------+
| Id | User | Host      | db        | Command | Time | State                           | Info                                                     |
+----+------+-----------+-----------+---------+------+---------------------------------+----------------------------------------------------------+
|  2 | root | localhost | tran_test | Query   |    0 | init                            | show processlist                                         |
|  3 | root | localhost | tran_test | Query   |    9 | Waiting for table metadata lock | alter table transaction_test add column hoge varchar(10) |
+----+------+-----------+-----------+---------+------+---------------------------------+----------------------------------------------------------+
2 rows in set (0.00 sec)
```

### ターミナル2
1分後にエラーとなること

```
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
```

### rollback
ターミナル1、2共に行う

```
term-1 > rollback;
```

## その他ロック
`transaction_test2`を作成しinsertを行う

### ターミナル1
```
term-1 > create table transaction_test2 ( id int(8) not null AUTO_INCREMENT, col1 char(1) not null, col2 int(8), rec_date datetime, PRIMARY KEY (id), key (col2), key (rec_date));

term-1 > insert into transaction_test2 select * from transaction_test;
Query OK, 9 rows affected (0.01 sec)
Records: 9  Duplicates: 0  Warnings: 0

```

### ターミナル2
応答が返らず待ち状態になること

```
term-2 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,28,'2010-04-06');
```

### ターミナル1

```
term-1 > show processlist;
+----+------+-----------+-----------+---------+------+--------+-----------------------------------------------------------------------------------+
| Id | User | Host      | db        | Command | Time | State  | Info                                                                              |
+----+------+-----------+-----------+---------+------+--------+-----------------------------------------------------------------------------------+
|  2 | root | localhost | tran_test | Query   |    0 | init   | show processlist                                                                  |
|  3 | root | localhost | tran_test | Query   |   23 | update | insert into transaction_test (col1, col2,rec_date) values ( 'a' ,28,'2010-04-06') |
+----+------+-----------+-----------+---------+------+--------+-----------------------------------------------------------------------------------+
2 rows in set (0.00 sec)
```

### ターミナル1
競合の確認

```
term-1 > select * from information_schema.innodb_locks;
+--------------+-------------+-----------+-----------+--------------------------------+------------+------------+-----------+----------+------------------------+
| lock_id      | lock_trx_id | lock_mode | lock_type | lock_table                     | lock_index | lock_space | lock_page | lock_rec | lock_data              |
+--------------+-------------+-----------+-----------+--------------------------------+------------+------------+-----------+----------+------------------------+
| 15121:24:3:1 | 15121       | X         | RECORD    | `tran_test`.`transaction_test` | PRIMARY    |         24 |         3 |        1 | supremum pseudo-record |
| 15116:24:3:1 | 15116       | S         | RECORD    | `tran_test`.`transaction_test` | PRIMARY    |         24 |         3 |        1 | supremum pseudo-record |
+--------------+-------------+-----------+-----------+--------------------------------+------------+------------+-----------+----------+------------------------+
2 rows in set (0.00 sec)
```

### ターミナル2
1分後にエラーとなること

```
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
```

### ターミナル1
競合の確認

```
term-1 > select * from information_schema.innodb_locks;
Empty set (0.00 sec)
```

### rollback
ターミナル1、2共に行う

```
term-1 > rollback;
```

