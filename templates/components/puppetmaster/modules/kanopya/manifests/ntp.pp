class kanopya::ntp {
    class { 'ntp':
        ensure     => running,
        autoupdate => true
    }
}
