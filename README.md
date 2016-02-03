# CentOS7-MySQLレプリケーションハンズオン環境
MySQLのレプリケーション環境の構築、レプリケーションの動作を学ぶための環境

## 前提
以下の2つのパッケージを事前に導入すること

[VAGRANT](https://www.vagrantup.com/)

[VirtualBox](https://www.virtualbox.org/)

メモリは各サーバ512Mで立ち上げるため1G必要

## SetUp
```
$ cd rep
$ vagrant up
```

## サーバ接続
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

| OS user | pass | 続DB | 接続Port |  DB user |  DB pass | 用途 |
|:-----------:|:------------:|:------------:|:------------:|:------------:|:------------:|:------------:|
| root | puppet | - | 3306 |  root | vagrant | root |
| vagrant | vagrant | - | - | - | - | vagrant用ユーザ |
| demouser | demouser | groupwork | 3306 | demouser | demopass | 検証用ユーザ |
