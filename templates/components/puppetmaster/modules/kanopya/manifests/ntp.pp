class kanopya::ntp::service($server) {
    class { '::ntp':
        ensure     => stopped,
        servers    => [ $server ]
    }

    exec { "ntpdate -b -u ${server}":
        path    => '/usr/sbin',
        require => Class['::ntp']
    }

    cron { 'ntpdate':
        command => "/usr/sbin/ntpdate -b -u ${server}",
        user    => root,
        hour    => 2
    }
}

class kanopya::ntp::install {
    package { 'ntpdate':
        name   => 'ntpdate',
        ensure => present
    }
}

class kanopya::ntp($server) {
    class { 'kanopya::ntp::service':
        server  => "$server",
        require => Class['kanopya::ntp::install']
    }

    class { 'kanopya::ntp::install': }
}

