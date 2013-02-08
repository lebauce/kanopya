class kanopya::lvm::install {
	package {
		'lvm':
			name => $operatingsystem ? {
				default => 'lvm2'
			},
			ensure => present,
	}
}

class kanopya::lvm {
	include kanopya::lvm::install
}

