class iscsitarget::service {
	service {
		'iscsitarget':
			name => $operatingsystem ? {
				default => 'iscsitarget'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
	}
}

class iscsitarget::install {
	package {
		'iscsitarget':
			name => $operatingsystem ? {
				default => 'iscsitarget'
			},
			ensure => present,
	}
}

class iscsitarget {
	include iscsitarget::install, iscsitarget::service
}

