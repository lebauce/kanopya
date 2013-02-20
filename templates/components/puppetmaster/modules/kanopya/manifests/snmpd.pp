class kanopya::snmpd::service {
	service {
		'snmpd':
			name => $operatingsystem ? {
				default => 'snmpd'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::snmpd::install'],
	}
}

class kanopya::snmpd::install {
	package {
		'snmpd':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'net-snmp',
				default => 'snmpd'
			},
			ensure => present,
	}
}

class kanopya::snmpd {
	include kanopya::snmpd::install, kanopya::snmpd::service
}

