class varnish::install{
    yumrepo { 'varnish':
        descr => 'varnish repo',
        baseurl => 'https://repo.varnish-cache.org/redhat/varnish-3.0/el$releasever/$basearch',
        enabled    => 1,
        gpgcheck   => 0,
        gpgkey     => 'https://repo.varnish-cache.org/GPG-key.txt',
    }

    yumrepo { 'varnish-epel':
        descr => 'epel repo',
        mirrorlist => 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch',
        enabled    => 1,
        gpgcheck   => 1,
        gpgkey     => 'https://fedoraproject.org/static/0608B895.txt',
        require => Yumrepo['varnish'],
    }

    package{
        [
        'varnish',
        ]:
        provider => 'yum',
        ensure => installed,
        require => Yumrepo['varnish-epel'],
    }
}
