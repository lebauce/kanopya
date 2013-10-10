class kanopya::dhcpd::service {
	service {
		'dhcpd':
			name => $operatingsystem ? {
				/(RedHat|CentOS|Fedora)/ => 'dhcpd',
				default => 'isc-dhcp-server'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
			require => Class['kanopya::dhcpd::install'],
	}
}

class kanopya::dhcpd::install {
	package {
		'dhcpd':
			name => $operatingsystem ? {
				/(RedHat|CentOS|Fedora)/ => 'dhcp',
				default => 'isc-dhcp-server'
			},
			ensure => present,
	}
}

class kanopya::dhcpd {
	include kanopya::dhcpd::install, kanopya::dhcpd::service
}

