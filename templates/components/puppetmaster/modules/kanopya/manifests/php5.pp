class kanopya::php5::install {
	package {
		'php5':
			name => $operatingsystem ? {
                                /(Red Hat|CentOS|Fedora)/ => [  'php-mysql' ],
				default => [ 'php5-mysql' ]
			},
			ensure => present,
	}
}

class kanopya::php5 {
	include kanopya::php5::install
}

