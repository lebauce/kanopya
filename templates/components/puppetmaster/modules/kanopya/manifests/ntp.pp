class kanopya::ntp($server) {
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
