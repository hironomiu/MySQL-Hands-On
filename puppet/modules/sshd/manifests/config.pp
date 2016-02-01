class sshd::config{
    exec { "sshd_conf" :
        user => 'root',
        path => ['/bin/','/usr/bin'],
        command => 'echo AllowUsers vagrant demouser >> /etc/ssh/sshd_config',
        unless => 'grep AllowUsers /etc/ssh/sshd_config',
        timeout => 999,
    }
}
