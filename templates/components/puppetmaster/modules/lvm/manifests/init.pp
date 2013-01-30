class lvm::install {
	package {
		'lvm':
			name => $operatingsystem ? {
				default => 'lvm2'
			},
			ensure => present,
	}
}

class lvm {
	include lvm::install
}

