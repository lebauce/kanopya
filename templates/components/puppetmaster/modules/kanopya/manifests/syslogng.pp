class kanopya::syslogng::service {
	service {
		'syslogng':
			name => $operatingsystem ? {
				default => 'syslog-ng'
			},
			ensure => running,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::syslogng::install']
	}
}

class kanopya::syslogng::install {
	package {
		'syslogng':
			name => $operatingsystem ? {
				default => 'syslog-ng'
			},
			ensure => present,
	}
}

class kanopya::syslogng {
	include kanopya::syslogng::install, kanopya::syslogng::service
}

