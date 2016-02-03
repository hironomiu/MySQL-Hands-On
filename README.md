# CentOS7-MySQLレプリケーションハンズオン環境
MySQLのレプリケーション環境の構築、レプリケーションの動作を学ぶための環境

## Install
```
$ git clone git@github.com:hironomiu/rep.git
```
or
```
$ git clone https://github.com/hironomiu/rep.git
```

## SetUp
```
$ cd rep
$ vagrant up
```

## 接続
### db1
```
$ vagrant ssh db1
```

### db2
```
$ vagrant ssh db2
```

### root遷移(db1,db2共通)
```
$ sudo su -
```

## 環境
|サーバ|IP|用途|
|:-:|:-:|:-:|
|db1|192.168.56.101|Master|
|db2|192.168.56.102|Slave|
