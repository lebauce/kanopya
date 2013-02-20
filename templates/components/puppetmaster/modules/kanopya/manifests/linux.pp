class kanopya::linux ($sourcepath) {
	file { '/etc/hosts':
		path    => '/etc/hosts',
		ensure  => present,
		mode    => 0644,
		source  => "puppet:///kanopyafiles/${sourcepath}/etc/hosts",
	}
	file { '/etc/resolv.conf':
		path    => '/etc/resolv.conf',
		ensure  => present,
		mode    => 0644,
		source  => "puppet:///kanopyafiles/${sourcepath}/etc/resolv.conf",
	}
}
