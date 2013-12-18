class kanopya::syslogng {
  service {
    'syslogng':
      name       => $operatingsystem ? {
        default => 'syslog-ng'
      },
      ensure     => running,
      hasrestart => true,
      enable     => true,
      require    => Package['syslog-ng']
  }

  package {
    'syslogng':
      ensure => present,
      name   => 'syslog-ng'
  }
}
