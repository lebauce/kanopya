class kanopya::openiscsi::service {
	service {
		'openiscsi':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'iscsid',
				default => 'open-iscsi'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::openiscsi::install'],
	}
}

class kanopya::openiscsi::install {
	package {
		'openiscsi':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'iscsi-initiator-utils',
				default => 'open-iscsi'
			},
			ensure => present,
	}
}

class kanopya::openiscsi {
	include kanopya::openiscsi::install, kanopya::openiscsi::service
}

