class php::config {
    file { '/etc/php.ini':
        owner => 'root', group => 'root',
        content => template('php/php.ini'),
    }

    file { '/etc/httpd/conf/httpd.conf':
        owner => 'root', group => 'root',
        content => template('php/httpd.conf'),
    }

    file { "/etc/sysconfig/memcached":
        owner => "root", group => "root",
        content => template('php/memcached'),
    }

    exec { "sshd_conf" :
        user => 'root',
        path => ['/bin/','/usr/bin'],
        command => 'echo AllowUsers vagrant demouser >> /etc/ssh/sshd_config',
        unless => 'grep AllowUsers /etc/ssh/sshd_config',
        timeout => 999,
    }

    exec { "locale" :
        user => 'root',
        path => ['/bin/','/usr/bin'],
        command => 'localectl set-locale LANG=ja_JP.utf8',
        timeout => 999,
    }

    exec { "timezone" :
        user => 'root',
        path => ['/bin/','/usr/bin'],
        command => 'timedatectl set-timezone Asia/Tokyo',
        timeout => 999,
    }
}
