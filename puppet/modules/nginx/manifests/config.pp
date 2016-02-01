class nginx::config{
    file { '/etc/nginx/conf.d/my.conf':
        owner => 'root', group => 'root',
        content => template('nginx/my.conf'),
    }
}
