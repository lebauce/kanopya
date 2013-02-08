class kanopya::puppetmaster::service {
	service {
		'puppetmaster':
			name => $operatingsystem ? {
				default => 'puppetmaster'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::puppetmaster::install'],
	}
}

class kanopya::puppetmaster::install {
	package {
		'puppetmaster':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'puppet-server',
				default => 'puppetmaster'
			},
			ensure => present,
	}
}

class kanopya::puppetmaster {
	include kanopya::puppetmaster::install, kanopya::puppetmaster::service
}

