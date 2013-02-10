class kanopya::openstack::repository {
	if $operatingsystem =~ /(?i)(ubuntu)/ {
		package { 'ubuntu-cloud-keyring':
			name => 'ubuntu-cloud-keyring',
			ensure => present,
		}
		apt::source { 'ubuntu-cloud-repository':
			location => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
			release  => 'precise-updates/folsom',
			repos    => 'main',
		}
	}
}

class kanopya::keystone($dbserver, $password) {
	@@mysql::db { 'keystone':
		user     => 'keystone',
		password => "${password}",
		host     => "${ipaddress}",
		grant    => ['all'],
		tag      => "${dbserver}",
	}
}
