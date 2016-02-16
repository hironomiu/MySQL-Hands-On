# MySQLレプリケーション環境構築ワーク

## 初期化パラメータmy.cnfの設定  
`[mysqld]`以下に追記する事  

### Master
    
```
# vi /etc/my.cnf  

+ server_id = 1
+ log_bin = /var/lib/mysql/mysql-bin
+ binlog_format = mixed
```

再起動

```
# service mysql restart 
```

### Slave
read_onlyで設定  

```
# vi /etc/my.cnf  

+ server_id = 2  
+ relay_log= mysql-relay-bin   
+ log-slave-updates
+ read_only
```

再起動

```
# service mysql restart  
```

## レプリケーションユーザの作成
`XXX.XXX.XXX.XXX`のIPはSlaveのIPを設定すること

### Master
MySQLにログインしGRANT文を実行する

```
# mysql   
mysql> GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replicator'@'XXX.XXX.XXX.XXX' IDENTIFIED BY 'replicator';  
```
## ポジションの確認
### Master
```
# mysql  
mysql> show master status;  
```

## レプリケーションの設定
`XXX.XXX.XXX.XXX`のIPはMasterのIPを設定すること

`mysql-bin.XXXXXX`は`show master status`で取得したFileの値を設定すること

`YYY`は`show master status`で取得したPositionの値を設定すること

### Slave
```
# mysql  
mysql> change master to  
  master_host = 'XXX.XXX.XXX.XXX',  
  master_user='replicator',  
  master_password='replicator',  
  master_port =3306,  
  master_log_file='mysql-bin.XXXXXX',  
  master_log_pos=YYY;  
```

## レプリケーション開始
### Slave
`start slave;`前後でのプロセス状況を`show processlist;`で確認する

エラーとならず、2個のsystemuserが存在すること

```   
mysql> show processlist;
mysql> start slave;
mysql> show processlist;
``` 


### Master
Slaveの`start slave`後、1個のreplicatorが存在すること

```
mysql> show processlist;  
```


 
## レプリケーションのステータス確認
### Slave 
Slave_IO_RunningがYesとなっていること

Slave_SQL_RunningがYesとなっていること


```
mysql> show slave status\G 
``` 

## 動作確認：DB作成

### Master、Slaveともに
これから作成する`rep_test`が存在しないこと

```
# mysql
mysql> show databases;
```

### Master
```
# mysql
mysql> create database rep_test;
```

### Master、Slaveともに
`rep_test`が存在すること

```
# mysql
mysql> show databases;
```


## 動作確認：テーブル作成
### Master、Slaveともに
テーブルが存在しないこと
 
```  
mysql> use rep_test  
mysql> show tables;
```

### Master
テーブルを作成

```
mysql> create table test(id int);
```

### Master、Slaveともに
testテーブルが存在すること
```
mysql> show tables;
mysql> select * from test;  
```


## 動作確認：データ挿入
### Master、Slaveともに
0件(Empty set)であること

```
mysql> select * from test;
```

### Master
データ挿入

```
mysql> insert into test values(10); 
```

### Master、Slaveともに
MasterでInsertされた10が表示されること
```
mysql> select * from test;
```

## binlog,relaylogの確認
### Master
mysql-bin.XXXXXXは最新のファイルを指定する。testテーブルの操作（create,insert）を確認

```
# cd /var/lib/mysql 
# cp mysql-bin.XXXXXX /tmp 
# cd /tmp 
# mysqlbinlog mysql-bin.XXXXXX > log.txt 
# vi log.txt 
```
 
### Slave
mysql-relay-bin.XXXXXXは最新のファイルを指定する。testテーブルの操作（create,insert）を確認

```
# cd /var/lib/mysql 
# cp mysql-relay-bin.XXXXXX /tmp 
# cd /tmp 
# mysqlbinlog mysql-relay-bin.XXXXXX > log.txt 
# vi log.txt   
```

