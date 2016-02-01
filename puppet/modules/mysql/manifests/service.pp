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
        command => "/usr/bin/mysql --defaults-file=/root/.my.cnf --connect-expired-password -e \"SET PASSWORD FOR root@'localhost'= PASSWORD('$passwd');\" ; echo [client] > /root/.my.cnf ; echo user = root >> /root/.my.cnf ; echo password = $passwd >> /root/.my.cnf",
        timeout => 999,
        require => Service['mysql'],
    }
}
