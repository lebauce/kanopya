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
	include syslogng::install
}

