class openldap::service {
	service {
		'openldap':
			name => $operatingsystem ? {
				default => 'slapd'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
	}
}

class openldap::install {
	package {
		'openldap':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'openldap-servers',
				default => 'slapd'
			},
			ensure => present,
	}
}

class openldap {
	include openldap::install, openldap::service
}

