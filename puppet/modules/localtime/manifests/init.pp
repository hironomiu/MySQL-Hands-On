class localtime{
    include localtime::install
    include localtime::config
    include localtime::service

       Class['localtime::install']
    -> Class['localtime::config']
    ~> Class['localtime::service']
}
