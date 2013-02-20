class kanopya::atftpd::service {
	service {
		'atftpd':
			name => $operatingsystem ? {
				default => 'atftpd'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::atftpd::install'],
	}
}

class kanopya::atftpd::install {
	package {
		'atftpd':
			name => $operatingsystem ? {
				default => 'atftpd'
			},
			ensure => present,
	}
}

class kanopya::atftpd {
	include kanopya::atftpd::install, kanopya::atftpd::service
}

