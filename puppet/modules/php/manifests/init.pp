class php{
    include php::install
    include php::config
    include php::service

       Class['php::install']
    -> Class['php::config']
    ~> Class['php::service']
}
