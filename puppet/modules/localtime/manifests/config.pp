class localtime::config {
    file { "/etc/localtime":
        owner => "root", group => "root",
        content => template('/usr/share/zoneinfo/Asia/Tokyo'),
    }
}
