# バックアップリストア

## OSコマンドを用いたコールド(オフライン)バックアップ、リカバリ、リストア

### 事前準備
作成済みのvagrant環境を削除、Vagrantfileを編集(19-30までコメントアウト)後、作成しrootに遷移

```
$ vagrant destroy
$ vi Vagrantfile
 19 #  config.vm.define :db2 do |db|
 20 #   db.vm.hostname = "db2"
 21 #   db.vm.network :private_network, ip: "192.168.56.102"
 22 #   db.vm.provider :virtualbox do |vb|
 23 #     vb.customize ["modifyvm", :id, "--memory", "512"]
 24 #     vb.name = "db2"
 25 #   end
 26 #   db.vm.provision :puppet, :options => '--modulepath="/vagrant/puppet/modules":"/vagrant/puppet/roles"' do |puppet|
 27 #      puppet.manifests_path = "./puppet/manifests"
 28 #      puppet.manifest_file  = "app.pp"
 29 #   end
 30 #  end
$ vagrant up
$ vagrant ssh db1
$ sudo su -
```

設定ファイルの変更し再起動

```
# vi /etc/my.cnf
+ log_bin = /var/lib/mysql/mysql-bin
+ binlog_format = mixed
# service mysql restart
```

### 確認

MySQLホームディレクトリ配下の現在の状態を確認

```
# cd /var/lib/mysql
# ll
total 110632
-rw-rw---- 1 mysql mysql       56 Feb 22 15:28 auto.cnf
-rw-rw---- 1 mysql mysql        5 Feb 22 15:33 db1.pid
drwx------ 2 mysql mysql       19 Feb 22 15:28 groupwork
-rw-rw---- 1 mysql mysql 12582912 Feb 22 15:33 ibdata1
-rw-rw---- 1 mysql mysql 50331648 Feb 22 15:33 ib_logfile0
-rw-rw---- 1 mysql mysql 50331648 Feb 22 15:28 ib_logfile1
drwx------ 2 mysql mysql     4096 Feb 22 15:28 mysql
-rw-rw---- 1 mysql mysql      120 Feb 22 15:33 mysql-bin.000001
-rw-rw---- 1 mysql mysql       32 Feb 22 15:33 mysql-bin.index
-rw-rw---- 1 mysql mysql    11721 Feb 22 15:33 mysql.err
-rw-rw---- 1 mysql mysql      366 Feb 22 15:33 mysql-slow.log
srwxrwxrwx 1 mysql mysql        0 Feb 22 15:33 mysql.sock
drwx------ 2 mysql mysql     4096 Feb 22 15:28 performance_schema
```

バックアップ用の退避ディレクトリの作成

```
# mkdir /tmp/backup
```

バックアップ確認用のデータ投入

```
# mysql
mysql> use groupwork
mysql> show tables;
Empty set (0.00 sec)

mysql> create table backup( id int,col varchar(10));

mysql> insert into backup values(1,'abcdefg');

mysql> select * from backup;
+------+---------+
| id   | col     |
+------+---------+
|   1  | abcdefg |
+------+---------+
1 row in set (0.00 sec)

mysql> exit;
```

### コールドバックアップ

MySQLの停止

```
# service mysql stop
```

停止後の状況確認

```
# ll
total 110632
-rw-rw---- 1 mysql mysql       56 Feb 22 15:28 auto.cnf
drwx------ 2 mysql mysql       53 Feb 22 15:36 groupwork
-rw-rw---- 1 mysql mysql 12582912 Feb 22 15:36 ibdata1
-rw-rw---- 1 mysql mysql 50331648 Feb 22 15:36 ib_logfile0
-rw-rw---- 1 mysql mysql 50331648 Feb 22 15:28 ib_logfile1
drwx------ 2 mysql mysql     4096 Feb 22 15:28 mysql
-rw-rw---- 1 mysql mysql      513 Feb 22 15:36 mysql-bin.000001
-rw-rw---- 1 mysql mysql       32 Feb 22 15:33 mysql-bin.index
-rw-rw---- 1 mysql mysql    15442 Feb 22 15:36 mysql.err
-rw-rw---- 1 mysql mysql      366 Feb 22 15:33 mysql-slow.log
drwx------ 2 mysql mysql     4096 Feb 22 15:28 performance_schema
```

コールドバックアップ実施

```
# cp -R /var/lib/mysql/groupwork /tmp/backup/.
# cp -R /var/lib/mysql/ibdata1 /tmp/backup/.
# cp -R /var/lib/mysql/ib_logfile0 /tmp/backup/.
# cp -R /var/lib/mysql/ib_logfile1 /tmp/backup/.
# cp -R /var/lib/mysql/mysql /tmp/backup/.
# cp -R /var/lib/mysql/performance_schema /tmp/backup/.
# cp /etc/my.cnf /tmp/backup/.
# ll /tmp/backup/
total 110604
drwx------ 2 root root       53 Feb 22 15:37 groupwork
-rw-r----- 1 root root 12582912 Feb 22 15:37 ibdata1
-rw-r----- 1 root root 50331648 Feb 22 15:37 ib_logfile0
-rw-r----- 1 root root 50331648 Feb 22 15:37 ib_logfile1
-rw-r--r-- 1 root root      555 Feb 22 15:37 my.cnf
drwx------ 2 root root     4096 Feb 22 15:37 mysql
drwx------ 2 root root     4096 Feb 22 15:37 performance_schema
```

### コールドバックアップ後のデータの投入

起動によりスイッチしたロールフォワード対象のバイナリログ:mysql-bin.000002を認識

```
# service mysql start
# ll
total 110644
-rw-rw---- 1 mysql mysql       56 Feb 22 15:28 auto.cnf
-rw-rw---- 1 mysql mysql        5 Feb 22 15:38 db1.pid
drwx------ 2 mysql mysql       53 Feb 22 15:36 groupwork
-rw-rw---- 1 mysql mysql 12582912 Feb 22 15:38 ibdata1
-rw-rw---- 1 mysql mysql 50331648 Feb 22 15:38 ib_logfile0
-rw-rw---- 1 mysql mysql 50331648 Feb 22 15:28 ib_logfile1
drwx------ 2 mysql mysql     4096 Feb 22 15:28 mysql
-rw-rw---- 1 mysql mysql      513 Feb 22 15:36 mysql-bin.000001
-rw-rw---- 1 mysql mysql      120 Feb 22 15:38 mysql-bin.000002
-rw-rw---- 1 mysql mysql       64 Feb 22 15:38 mysql-bin.index
-rw-rw---- 1 mysql mysql    17570 Feb 22 15:38 mysql.err
-rw-rw---- 1 mysql mysql      549 Feb 22 15:38 mysql-slow.log
srwxrwxrwx 1 mysql mysql        0 Feb 22 15:38 mysql.sock
drwx------ 2 mysql mysql     4096 Feb 22 15:28 performance_schema
```

バックアップ後のデータの投入

```
# mysql
mysql> use groupwork;

mysql> insert into backup values(2,'bcdefgh');

mysql> select * from backup;
+------+---------+
| id   | col     |
+------+---------+
|    1 | abcdefg |
|    2 | bcdefgh |
+------+---------+
2 rows in set (0.00 sec)

mysql> exit;
```

### リカバリ

障害があったと想定し停止

```
# service mysql stop
```

コールドバックアップ時点まで復旧

```
# \cp -Rf /tmp/backup/groupwork /var/lib/mysql/.
# \cp -Rf /tmp/backup/ibdata1 /var/lib/mysql/.
# \cp -Rf /tmp/backup/mysql /var/lib/mysql/.
# \cp -Rf /tmp/backup/performance_schema /var/lib/mysql/.
# \cp -Rf /tmp/backup/ib_logfile0 /var/lib/mysql/.
# \cp -Rf /tmp/backup/ib_logfile1 /var/lib/mysql/.
# \cp -Rf /tmp/backup/my.cnf /etc/.
```

リモート接続禁止状態で起動(エンターでバックグランドで実行)

```
# mysqld_safe --defaults-file=/etc/my.cnf --skip-networking &
```

コールドバックアップ時点のデータが存在することを確認(=リカバリが成功)

```
# mysql

# use groupwork;

mysql> show tables;
+---------------------+
| Tables_in_groupwork |
+---------------------+
| backup              |
+---------------------+
1 row in set (0.00 sec)

mysql> select * from backup;
+------+---------+
| id   | col     |
+------+---------+
|   1  | abcdefg |
+------+---------+
1 row in set (0.00 sec)
```

### リストア(ロールフォワード)

適用するバイナリログの確認(以下の場合mysql-bin.000002、mysql-bin.000003)  
**実際の運用では`/var/lib/mysql`配下ではなくバックアップとは別なイベントで退避されているが今回は割愛する

```
# ll
total 110668
-rw-rw---- 1 mysql mysql       56 Feb 23 09:28 auto.cnf
-rw-rw---- 1 mysql mysql        5 Feb 23 09:42 db1.pid
drwx------ 2 mysql mysql       53 Feb 23 09:30 groupwork
-rw-rw---- 1 mysql mysql 12582912 Feb 23 09:42 ibdata1
-rw-rw---- 1 mysql mysql 50331648 Feb 23 09:42 ib_logfile0
-rw-rw---- 1 mysql mysql 50331648 Feb 23 09:36 ib_logfile1
drwx------ 2 mysql mysql     4096 Feb 23 09:28 mysql
-rw-rw---- 1 mysql mysql      513 Feb 23 09:31 mysql-bin.000001
-rw-rw---- 1 mysql mysql      385 Feb 23 09:35 mysql-bin.000002
-rw-rw---- 1 mysql mysql      120 Feb 23 09:42 mysql-bin.000003
-rw-rw---- 1 mysql mysql       96 Feb 23 09:42 mysql-bin.index
-rw-rw---- 1 mysql mysql    37662 Feb 23 09:42 mysql.err
-rw-rw---- 1 mysql mysql      729 Feb 23 09:42 mysql-slow.log
srwxrwxrwx 1 mysql mysql        0 Feb 23 09:42 mysql.sock
drwx------ 2 mysql mysql     4096 Feb 23 09:28 performance_schema
```

バイナリログの適用(リストア)

```
# mysqlbinlog --disable-log-bin mysql-bin.000002 mysql-bin.000003 > /tmp/recover.sql
# mysql --user=root -p < /tmp/recover.sql
```

適用後のデータを確認

```
# mysql

# use groupwork;


mysql> select * from backup;
+------+---------+
| id   | col     |
+------+---------+
|   1  | abcdefg |
|   2  | bcdefgh |
+------+---------+
2 rows in set (0.00 sec)
```

### 後処理
`mysqld_safe`での起動を停止

```
# mysqladmin -u root -p shutdown
```

正常起動に変更

```
# service mysql start
```

データ確認

```
# mysql
mysql> use groupwork;

mysql> show tables;
+---------------------+
| Tables_in_groupwork |
+---------------------+
| backup              |
+---------------------+
1 row in set (0.00 sec)

mysql> select * from backup;
+------+---------+
| id   | col     |
+------+---------+
|    1 | abcdefg |
|    2 | bcdefgh |
+------+---------+
2 rows in set (0.00 sec)

mysql> exit;
```
