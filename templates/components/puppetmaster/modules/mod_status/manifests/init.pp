class mod_status {
  file { "${apache::params::vdir}/status.conf":
    ensure => present,
    content => template('mod_status/status.conf.erb'),
  }
}
