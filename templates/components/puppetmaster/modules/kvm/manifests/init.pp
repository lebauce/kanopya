class kvm::service {
	service {
		'kvm':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'libvirtd',
				default => 'libvirt-bin'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
	}
	service {
		'dnsmasq':
			name => 'dnsmasq',
			ensure => stopped,
			hasstatus => true,
			hasrestart => true,
			enable => false,
	}
}

class kvm::install {
	package {
		'kvm':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'libvirt',
				default => 'libvirt-bin'
			},
			ensure => present,
	}
}

class kvm {
	include kvm::install, kvm::service
}

