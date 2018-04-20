# CentOS7-MySQLハンズオン環境
MySQLを使った動作を学ぶための環境

## ハンズオンの進め方
/document配下にある各種mdを参照し進めましょう

## 前提
以下の2つのパッケージを事前に導入すること

[VAGRANT](https://www.vagrantup.com/)

[VirtualBox](https://www.virtualbox.org/)

このハンズオンを行うPCは各サーバ512Mで立ち上げるためメモリが1G必要です

## SetUp
`vagrant up`を行うと2つの仮想マシン(db1,db2)が作成されます

```
$ cd MySQL-Hands-On 
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
vagrantユーザからsudoで遷移可能です

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

|OS user|pass|DB user|DB pass|紐付くDB|用途|
|:--------:|:--------:|:--------:|:--------:|:--------:|:--------:|:--------:|
| root | puppet |  root | vagrant | - | root |
| vagrant | vagrant | - | - | - | vagrant用ユーザ |
| demouser | demouser | demouser | demopass | groupwork | 検証用ユーザ |
