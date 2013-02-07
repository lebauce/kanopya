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
			require => Class['haproxy::install'],
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

