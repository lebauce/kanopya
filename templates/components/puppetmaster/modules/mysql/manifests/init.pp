class mysql::service {
	service {
		'mysql':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'mysqld',
				default => 'mysql'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
	}
}

class mysql::install {
	package {
		'mysql':
			name => $operatingsystem ? {
				default => 'mysql-server'
			},
			ensure => present,
	}
}

class mysql {
	include mysql::install, mysql::service
}

