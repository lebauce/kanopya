class nfsd::service {
	service {
		'nfsd':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'nfs',
				default => 'nfs-kernel-server'
			},
			ensure => running,
			hasstatus => true,
			hasrestart => true,
			enable => true,
	}
}

class nfsd::install {
	package {
		'nfsd':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'nfs-utils',
				default => 'nfs-kernel-server'
			},
			ensure => present,
	}
}

class nfsd {
	include nfsd::install, nfsd::service
}

