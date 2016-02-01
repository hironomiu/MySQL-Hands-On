class varnish::config {
    file { "/etc/varnish/varnish.params":
        owner => "root", group => "root",
        content => template('varnish/varnish.params'),
        notify => Service['varnish'],
    }
#    file { "/etc/varnish/default.vcl":
#        owner => "root", group => "root",
#        content => template('varnish/default.vcl'),
#        notify => Service['varnish'],
#    }
}
