class nfs::service {
	if $operatingsystem =~ /(Red Hat|CentOS|Fedora)/ {
		service {
			'nfs':
				name => 'rpcbind',
				ensure => running,
				hasstatus => true,
				hasrestart => true,
				enable => true,
				require => Class['nfs::install'],
		}
	}
}

class nfs::install {
	package {
		'nfs':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'nfs-utils',
				default => 'nfs-common'
			},
			ensure => present,
	}
}

class nfs {
	include nfs::install, nfs::service
}

