class sshd{
    include sshd::install
    include sshd::config
    include sshd::service

       Class['sshd::install']
    -> Class['sshd::config']
    ~> Class['sshd::service']
}
