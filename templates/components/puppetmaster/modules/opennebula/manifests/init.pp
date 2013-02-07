class opennebula::service {
	service {
		'opennebula':
			name => $operatingsystem ? {
				default => 'oned'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['opennebula::install'],
	}
}

class opennebula::install {
	package {
		'opennebula':
			name => $operatingsystem ? {
				default => 'opennebula'
			},
			ensure => present,
	}
}

class opennebula {
	include opennebula::install, opennebula::service
}

