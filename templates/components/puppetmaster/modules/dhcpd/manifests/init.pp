class dhcpd::service {
	service {
		'dhcpd':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'dhcpd',
				default => 'isc-dhcp-server'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
	}
}

class dhcpd::install {
	package {
		'dhcpd':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'dhcp',
				default => 'isc-dhcp-server'
			},
			ensure => present,
	}
}

class dhcpd {
	include dhcpd::install, dhcpd::service
}

