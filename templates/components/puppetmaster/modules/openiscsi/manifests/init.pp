class openiscsi::service {
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
			require => Class['openiscsi::install'],
	}
}

class openiscsi::install {
	package {
		'openiscsi':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'iscsi-initiator-utils',
				default => 'open-iscsi'
			},
			ensure => present,
	}
}

class openiscsi {
	include openiscsi::install, openiscsi::service
}

