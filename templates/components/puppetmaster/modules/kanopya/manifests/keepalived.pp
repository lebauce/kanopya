class kanopya::keepalived::service {
	service {
		'keepalived':
			name => $operatingsystem ? {
				default => 'keepalived'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::keepalived::install'],
	}
}

class kanopya::keepalived::install {
	package {
		'keepalived':
			name => $operatingsystem ? {
				default => 'keepalived'
			},
			ensure => present,
	}
}

class kanopya::keepalived {
	include kanopya::keepalived::install, kanopya::keepalived::service
}

