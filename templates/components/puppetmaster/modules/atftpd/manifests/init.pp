class atftpd::service {
	service {
		'atftpd':
			name => $operatingsystem ? {
				default => 'atftpd'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
	}
}

class atftpd::install {
	package {
		'atftpd':
			name => $operatingsystem ? {
				default => 'atftpd'
			},
			ensure => present,
	}
}

class atftpd {
	include atftpd::install, atftpd::service
}

