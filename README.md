# CentOS7-MySQLレプリケーション学習用環境

## install
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

