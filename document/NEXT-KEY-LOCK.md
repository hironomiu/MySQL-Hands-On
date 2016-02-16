# ネクストキーロックの検証

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

## 実技1　存在しないデータのdelete & insert
### ターミナル1
deleteは成功(OK)しているが、削除はしていない(0 rows)ことを確認

```
term-1 > delete from transaction_test where col2 = 28;
Query OK, 0 rows affected (0.00 sec)
```

### ターミナル2
deleteは成功(OK)しているが、削除はしていない(0 rows)ことを確認

```
term-2 > delete from transaction_test where col2 = 48;
Query OK, 0 rows affected (0.00 sec)
```

### ターミナル1
insertがロック待ちになること

```
term-1 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,49,'2010-04-06');
```

### ターミナル2
**ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction** となること

```
term-2 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,29,'2010-04-06');
ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
```

### ターミナル1
insert文の結果が返ること

```
Query OK, 1 row affected (12.56 sec)

```

### rollback
ターミナル1、2共に行う

```
term-1 > rollback;
```

## 実技2　存在するデータのdelete & insert
### ターミナル1
deleteは成功(OK)し、1件削除している(1 rows)ことを確認

```
term-1 > delete from transaction_test where col2 = 25;
Query OK, 1 row affected (0.00 sec)
```

### ターミナル2
deleteは成功(OK)し、1件削除している(1 rows)ことを確認

```
term-2 > delete from transaction_test where col2 = 45;
Query OK, 1 row affected (0.00 sec)
```

### ターミナル1
insertがロック待ちになること

```
term-1 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,48,'2010-04-06');
```

### ターミナル2
**ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction** となること

```
term-2 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,28,'2010-04-06');
ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
```

### ターミナル1
insert文の結果が返ること

```
Query OK, 1 row affected (33.01 sec)

```

### rollback
ターミナル1、2共に行う

```
term-1 > rollback;
```


## 実技3　存在しないデータのdelete & insert (unique index)
### ターミナル1
transaction_testのインデックスをnon uniqueからuniquiに変更する

```
term-1 > alter table transaction_test drop key col2;

term-1 > alter table transaction_test add unique index (col2);
```

### ターミナル1
deleteは成功(OK)しているが、削除はしていない(0 rows)ことを確認

```
term-1 > delete from transaction_test where col2 = 28;
Query OK, 0 rows affected (0.00 sec)
```

### ターミナル2
deleteは成功(OK)しているが、削除はしていない(0 rows)ことを確認

```
term-2 > delete from transaction_test where col2 = 48;
Query OK, 0 rows affected (0.00 sec)
```

### ターミナル1
insertがロック待ちになること

```
term-1 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,48,'2010-04-06');
```

### ターミナル2
**ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction** となること

```
term-2 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,28,'2010-04-06');
ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
```

### ターミナル1
insert文の結果が返ること

```
Query OK, 1 row affected (33.01 sec)

```

### rollback
ターミナル1、2共に行う

```
term-1 > rollback;
```

## 実技4　存在するデータのdelete & insert(unique index)
### ターミナル1
deleteは成功(OK)し、1件削除している(1 rows)ことを確認

```
term-1 > delete from transaction_test where col2 = 25;
Query OK, 1 row affected (0.00 sec)
```

### ターミナル2
deleteは成功(OK)し、1件削除している(1 rows)ことを確認

```
term-2 > delete from transaction_test where col2 = 45;
Query OK, 1 row affected (0.00 sec)
```

### ターミナル1
正常に終了すること

```
term-1 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,48,'2010-04-06');
Query OK, 1 row affected (0.00 sec)
```

### ターミナル2
正常に終了すること

```
term-2 > insert into transaction_test (col1, col2,rec_date) values ( 'a' ,28,'2010-04-06');
Query OK, 1 row affected (0.00 sec)
```

### ターミナル1
データの確認

```
term-1 > select * from transaction_test;
+----+------+------+---------------------+
| id | col1 | col2 | rec_date            |
+----+------+------+---------------------+
|  1 | b    |   35 | 2010-04-07 00:00:00 |
|  2 | a    |   40 | 2010-04-08 00:00:00 |
|  3 | c    |   20 | 2010-04-09 00:00:00 |
|  5 | a    |   50 | 2010-04-11 00:00:00 |
|  6 | c    |   10 | 2010-04-12 00:00:00 |
|  7 | b    |   45 | 2010-04-13 00:00:00 |
|  8 | a    |   15 | 2010-04-14 00:00:00 |
|  9 | c    |   30 | 2010-04-15 00:00:00 |
| 16 | a    |   48 | 2010-04-06 00:00:00 |
+----+------+------+---------------------+
9 rows in set (0.00 sec)

```

### ターミナル2
データの確認

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
|  8 | a    |   15 | 2010-04-14 00:00:00 |
|  9 | c    |   30 | 2010-04-15 00:00:00 |
| 17 | a    |   28 | 2010-04-06 00:00:00 |
+----+------+------+---------------------+
9 rows in set (0.00 sec)
```

### rollback
ターミナル1、2共に行う

```
term-1 > rollback;
```

## Question
実技1~4で実技4のみDeadLockが発生しない理由を考えましょう

