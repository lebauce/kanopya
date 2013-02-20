class kanopya::nfs::service {
	if $operatingsystem =~ /(Red Hat|CentOS|Fedora)/ {
		service {
			'nfs':
				name => 'rpcbind',
				ensure => running,
				hasstatus => true,
				hasrestart => true,
				enable => true,
				require => Class['kanopya::nfs::install'],
		}
	}
}

class kanopya::nfs::install {
	package {
		'nfs':
			name => $operatingsystem ? {
				/(Red Hat|CentOS|Fedora)/ => 'nfs-utils',
				default => 'nfs-common'
			},
			ensure => present,
	}
}

class kanopya::nfs {
	include kanopya::nfs::install, kanopya::nfs::service
}

