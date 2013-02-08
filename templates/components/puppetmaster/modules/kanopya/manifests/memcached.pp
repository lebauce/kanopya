class kanopya::memcached::service {
	service {
		'memcached':
			name => $operatingsystem ? {
				default => 'memcached'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::memcached::install'],
	}
}

class kanopya::memcached::install {
	package {
		'memcached':
			name => $operatingsystem ? {
				default => 'memcached'
			},
			ensure => present,
	}
}

class kanopya::memcached {
	include kanopya::memcached::install, kanopya::memcached::service
}

