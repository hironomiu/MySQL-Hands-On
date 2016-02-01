class mysql::config {
    file { "/etc/my.cnf":
        content => template('mysql/my.cnf'),
        notify => Service['mysql'],
    }
    exec { "passwd1" :
        user => 'root',
        path => ['/bin/','/usr/bin'],
        command => 'mv /.mysql_secret /root/.mysql_secret ; echo [client] > /root/.my.cnf ; echo user = root >> /root/.my.cnf ; cut -d ":" -f 4 /root/.mysql_secret | cut -c 2-17 | xargs echo password = >> /root/.my.cnf',
        timeout => 999,
        unless => "ls -la /root/.my.cnf",
    }
    exec { "passwd2" :
        user => 'root',
        path => ['/bin/','/usr/bin'],
        command => 'chmod 600 /root/.my.cnf',
        timeout => 999,
        unless => "ls -la /root/.my.cnf",
        require => Exec['passwd1']
    }
}
