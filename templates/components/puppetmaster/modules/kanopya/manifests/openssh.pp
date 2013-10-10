class kanopya::openssh::service {
	service {
		'openssh':
			name => $operatingsystem ? {
				/(RedHat|CentOS|Fedora)/ => 'sshd',
				default => 'ssh'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::openssh::install'],
	}
}

class kanopya::openssh::install {
	package {
		'openssh':
			name => $operatingsystem ? {
				default => 'openssh-server'
			},
			ensure => present,
	}
}

class kanopya::openssh {
	include kanopya::openssh::install, kanopya::openssh::service
}

