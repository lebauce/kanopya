class openssh::service {
	service {
		'openssh':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'sshd',
				default => 'ssh'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['openssh::install'],
	}
}

class openssh::install {
	package {
		'openssh':
			name => $operatingsystem ? {
				default => 'openssh-server'
			},
			ensure => present,
	}
}

class openssh {
	include openssh::install, openssh::service
}

