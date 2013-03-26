class kanopya::ntp($server) {
    class { '::ntp':
        ensure     => running,
        autoupdate => true,
        servers    => [ $server ]
    }
}
