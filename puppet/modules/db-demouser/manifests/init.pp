class db-demouser{
    include db-demouser::install
    include db-demouser::config

       Class['db-demouser::install']
    -> Class['db-demouser::config']
}
