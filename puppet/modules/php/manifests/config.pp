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

}
