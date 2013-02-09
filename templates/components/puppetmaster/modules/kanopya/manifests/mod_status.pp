class kanopya::mod_status {
  file { "${apache::params::vdir}/status.conf":
    ensure => present,
    content => template('kanopya/status.conf.erb'),
  }
}
