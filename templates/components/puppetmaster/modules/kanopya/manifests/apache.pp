class kanopya::apache {
    class { '::apache': }
    class { 'kanopya::mod_status': }
}
