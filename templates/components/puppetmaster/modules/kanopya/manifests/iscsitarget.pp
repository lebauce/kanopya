class kanopya::iscsitarget {
	package { 'iscsitarget':
		ensure => present,
	}

	service { 'iscsitarget':
		ensure   => running,
		enable   => true,
		require  => Package['iscsitarget'],
	}

	service { 'open-iscsi':
		ensure   => running,
		enable   => true,
		require  => Service['iscsitarget'],
	}

	package { 'iscsitarget-dkms':
		ensure => present,
	}

	file { '/etc/default/iscsitarget':
		content => "ISCSITARGET_ENABLE=true\n",
	}
}

