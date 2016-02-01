class varnish{
    include varnish::install
    include varnish::config
    include varnish::service

       Class['varnish::install']
    -> Class['varnish::config']
    ~> Class['varnish::service']
}
