class mysql::service {
    include variables::config
    $passwd = $variables::config::passwd

    service{ 'mysql':
        enable => true,
        ensure => running,
        hasrestart => true,
    }

    exec { "db-set-root-pass":
        user => 'root',
        path => ['/bin/','/usr/bin'],
        command => "/usr/bin/mysql --defaults-file=/root/.my.cnf --connect-expired-password -e \"SET PASSWORD FOR root@'localhost'= PASSWORD('$passwd');\" ; echo [client] > /root/.my.cnf ; echo user = root >> /root/.my.cnf ; echo password = $passwd >> /root/.my.cnf;",
        timeout => 999,
        require => Service['mysql'],
    }

    exec { "db-create-demouser":
        unless => "/usr/bin/mysql -udemouser -pdemouser -e \"show databases;\"",
        command => "/usr/bin/mysql -uroot -p$passwd -e \"create database groupwork; grant all on groupwork.* to demouser@'%' identified by 'demopass';grant all on groupwork.* to demouser@localhost identified by 'demopass';drop user ''@'`hostname`';drop user ''@'localhost';\"",
        require => Exec['db-set-root-pass'],
    }

}
