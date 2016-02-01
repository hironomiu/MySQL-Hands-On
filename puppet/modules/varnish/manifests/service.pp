class varnish::service {
    service{ 'varnish':
        enable => true,
        ensure => running,
        hasrestart => true,
    }
}
