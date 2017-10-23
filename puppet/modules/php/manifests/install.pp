class php::install{
    package{'epel-release':
        provider => 'yum',
        ensure => installed
    }
    
    exec { 'remi-release':
        user => 'root',
        path => ['/bin/','/usr/bin'],
        command => 'rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm',
        timeout => 999,
    }

    package{ 
        'httpd':
        provider => 'yum',
        ensure => 'latest',
        require => Exec['remi-release']
    }

    package{ 
        'php':
        provider => 'yum',
        ensure => 'latest',
        install_options => ['--enablerepo=remi-php72','--noplugins'],
        require => Package['httpd']
    }

    package{
        [
        'php-cli',
        'php-common',
        'php-pdo',
        'php-mbstring',
        'php-mysqlnd',
        'php-devel',
        'php-fpm',
        'php-xml',
        'php-mcrypt',
        'libmcrypt',
        'memcached',
        'php-pecl-memcached',
        'openssh-clients',
        'wget',
        'git',
        'screen',
        'unzip',
        'make',
        'dstat',
        'emacs',
        'vim-enhanced',
        'telnet',
        'tree',
        'sysstat',
        'perf',
        'cronie-noanacron',
        'npm',
        ]:
        provider => 'yum',
        ensure => latest,
        install_options => ['--enablerepo=remi,remi-php72,epel','--noplugins'],
        require => Package['php']
    }

    package{
        [
        'siege',
        ]:
        provider => 'yum',
        ensure => latest,
        install_options => ['--enablerepo=epel','--noplugins'],
        require => Package['php']
    }

    package{
        [
        'cronie-anacron',
        ]:
        ensure => purged,
        require => Package['remi-release']
    }

}
