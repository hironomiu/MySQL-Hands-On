class nginx::service {
    service{ 'nginx':
        enable => false,
        ensure => stopped,
        hasrestart => false,
    }
}
