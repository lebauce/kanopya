class php::install {
	package {
		'php':
			name => $operatingsystem ? {
                                /(Red Hat|CentOS|Fedora)/ => 'php',
				default => 'php5'
			},
			ensure => present,
	}
}

class php {
	include php::install
}

