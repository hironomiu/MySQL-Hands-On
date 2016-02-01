class lang::config {
    file { "/etc/sysconfig/i18n":
        owner => "root", group => "root",
        content => template('lang/i18n'),
    }
}
