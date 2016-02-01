class sshd::service {
    service{ 'sshd':
        enable => true,
        ensure => running,
        hasrestart => true,
    }
}
