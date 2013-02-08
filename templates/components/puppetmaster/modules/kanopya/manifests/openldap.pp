class kanopya::openldap::service {
	service {
		'openldap':
			name => $operatingsystem ? {
				default => 'slapd'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::openldap::install'],
	}
}

class kanopya::openldap::install {
	package {
		'openldap':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'openldap-servers',
				default => 'slapd'
			},
			ensure => present,
	}
}

class kanopya::openldap {
	include kanopya::openldap::install, kanopya::openldap::service
}

