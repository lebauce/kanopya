class kanopya::openstack::repository {
  if $operatingsystem =~ /(?i)(ubuntu)/ {
    package { 'ubuntu-cloud-keyring':
      name    => 'ubuntu-cloud-keyring',
      ensure  => present,
      require => Exec['apt-get update']
    }

    exec { 'apt-get -q update':
      path        => '/usr/bin',
      tries       => 5,
      subscribe   => Package['ubuntu-cloud-keyring'],
      refreshonly => true
    }

    file { '/etc/apt/sources.list.d/ubuntu-cloud-repository.list':
      content => "# ubuntu-cloud-repository\ndeb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main\ndeb-src http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly m
      require => Package['ubuntu-cloud-keyring']
    }
  }  
}
