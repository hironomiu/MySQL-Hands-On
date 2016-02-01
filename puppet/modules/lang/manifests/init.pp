class lang{
    include lang::install
    include lang::config
    include lang::service

       Class['lang::install']
    -> Class['lang::config']
    ~> Class['lang::service']
}
