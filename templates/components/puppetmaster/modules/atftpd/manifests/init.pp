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
			require => Class['atftpd::install'],
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

