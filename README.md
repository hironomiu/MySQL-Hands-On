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
### サーバ
|サーバ|IP|用途|
|:-:|:-:|:-:|
|db1|192.168.56.101|Master|
|db2|192.168.56.102|Slave|

### ユーザ
サーバdb1,2ともに共通

| OS user | pass |  DB user |  DB pass | 紐付くDB | 用途 |
|:--------:|:--------:|:--------:|:--------:|:--------:|:--------:|:--------:|
| root | puppet |  root | vagrant | - | root |
| vagrant | vagrant | - | - | - | vagrant用ユーザ |
| demouser | demouser | demouser | demopass | groupwork | 検証用ユーザ |

