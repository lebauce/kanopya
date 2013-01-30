class memcached::service {
	service {
		'memcached':
			name => $operatingsystem ? {
				default => 'memcached'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
	}
}

class memcached::install {
	package {
		'memcached':
			name => $operatingsystem ? {
				default => 'memcached'
			},
			ensure => present,
	}
}

class memcached {
	include memcached::install, memcached::service
}

