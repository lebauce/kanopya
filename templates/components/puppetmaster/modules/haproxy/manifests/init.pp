class haproxy::service {
	service {
		'haproxy':
			name => $operatingsystem ? {
				default => 'haproxy'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
	}
}

class haproxy::install {
	package {
		'haproxy':
			name => $operatingsystem ? {
				default => 'haproxy'
			},
			ensure => present,
	}
}

class haproxy {
	include haproxy::install
}

