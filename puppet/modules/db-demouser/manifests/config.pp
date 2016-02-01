class db-demouser::config {
    include variables::config
    $passwd = $variables::config::passwd
    include mysql::service
    Class['mysql::service'] -> Class['db-demouser::config']
    exec { "db-create-demouser":
        unless => "/usr/bin/mysql -udemouser -pdemouser -e \"show databases;\"",
        command => "/usr/bin/mysql -uroot -p$passwd -e \"create database groupwork; grant all on groupwork.* to demouser@localhost identified by 'demopass';\"",
    }
}
