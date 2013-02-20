class kanopya::opennebula::service {
	service {
		'opennebula':
			name => $operatingsystem ? {
				default => 'oned'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::opennebula::install'],
	}
}

class kanopya::opennebula::install {
	package {
		'opennebula':
			name => $operatingsystem ? {
				default => 'opennebula'
			},
			ensure => present,
	}
}

class kanopya::opennebula {
	include kanopya::opennebula::install, kanopya::opennebula::service
}

