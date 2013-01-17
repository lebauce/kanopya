class snmpd::service {
	service {
		'snmpd':
			name => $operatingsystem ? {
				default => 'snmpd'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
	}
}

class snmpd::install {
	package {
		'snmpd':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'net-snmp',
				default => 'snmpd'
			},
			ensure => present,
	}
}

class snmpd {
	include snmpd::install, snmpd::service
}

