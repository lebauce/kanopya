class kanopya::haproxy::service {
	service {
		'haproxy':
			name => $operatingsystem ? {
				default => 'haproxy'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::haproxy::install'],
	}
}

class kanopya::haproxy::install {
	package {
		'haproxy':
			name => $operatingsystem ? {
				default => 'haproxy'
			},
			ensure => present,
	}
}

class kanopya::haproxy {
	include kanopya::haproxy::install
}

