class nginx::install{
    include php::config
    Class['php::config'] -> Class['nginx::install']
    yumrepo { 'nginx':
        descr => 'nginx yum repo',
        baseurl => 'http://nginx.org/packages/centos/7/$basearch/',
        enabled    => 1,
        gpgcheck   => 0,
    }

    package{
        'nginx':
        ensure => installed,
        require => Yumrepo['nginx'],
    }
}
