class kanopya::ntp::server {
    $servers = [ "ntp.pool.org", "ntp.lip6.fr", "ntp.ubuntu.com" ]

    class { '::ntp':
        ensure   => running,
        servers  => $servers,
        restrict => false
    }
}

class kanopya::ntp::ntpdate($server) {
    class { '::ntp':
        ensure     => stopped,
        servers    => [ $server ],
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

class kanopya::ntp::client($server) {
    class { 'kanopya::ntp::ntpdate':
        server   => "$server",
        require  => Class['kanopya::ntp::install']
    }

    class { 'kanopya::ntp::install': }
}

