class kanopya::iscsitarget::service {
	service {
		'iscsitarget':
			name => $operatingsystem ? {
				default => 'iscsitarget'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::iscsitarget::install'],
	}
}

class kanopya::iscsitarget::install {
	package {
		'iscsitarget':
			name => $operatingsystem ? {
				default => 'iscsitarget'
			},
			ensure => present,
	}
}

class kanopya::iscsitarget {
	include kanopya::iscsitarget::install, kanopya::iscsitarget::service
}

