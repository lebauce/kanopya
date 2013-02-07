class puppetmaster::service {
	service {
		'puppetmaster':
			name => $operatingsystem ? {
				default => 'puppetmaster'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['puppetmaster::install'],
	}
}

class puppetmaster::install {
	package {
		'puppetmaster':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'puppet-server',
				default => 'puppetmaster'
			},
			ensure => present,
	}
}

class puppetmaster {
	include puppetmaster::install, puppetmaster::service
}

