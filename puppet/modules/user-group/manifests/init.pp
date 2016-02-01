class user-group{
    include user-group::install
    include user-group::config

       Class['user-group::install']
    -> Class['user-group::config']
}
