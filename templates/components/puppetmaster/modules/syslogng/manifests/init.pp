class syslogng::service {
	service {
		'syslogng':
			name => $operatingsystem ? {
				default => 'syslog-ng'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['syslogng::install']
	}
}

class syslogng::install {
	package {
		'syslogng':
			name => $operatingsystem ? {
				default => 'syslog-ng'
			},
			ensure => present,
	}
}

class syslogng {
	include syslogng::install, syslogng::service
}

