class kanopya::puppetmaster::repository {
  $release = downcase($lsbdistcodename)
  $os = downcase($operatingsystem)

  case $operatingsystem {
    /(?i)(debian|ubuntu)/ : {
      @apt::source { 'puppetlabs':
        location    => "http://apt.puppetlabs.com/",
        release     => $release,
        repos       => 'main',
        key         => '4BD6EC30',
        key_server  => 'keyserver.ubuntu.com',
	include_src => false,
        before      => [ Package['puppetdb'],
                         Package['puppetdb-terminus'] ]
      }
    }
    /(?i)(centos|redhat)/ : {
      yumrepo { 'puppetlabs-products':
        baseurl  => 'http://yum.puppetlabs.com/el/$releasever/products/$basearch/',
        enabled  => '1',
        gpgcheck => '1',
        gpgkey   => 'http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
      }
      yumrepo { 'puppetlabs-deps':
        baseurl  => 'http://yum.puppetlabs.com/el/$releasever/dependencies/$basearch/',
        enabled  => '1',
        gpgcheck => '1',
        gpgkey   => 'http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
      }
    }
    default : {
      fail("Unsupported operatingsystem : ${operatingsystem}. Only Debian, Ubuntu and Debian are supported")
    }
  }
}

class kanopya::puppetmaster(
  $sections = []
) {

  class { 'kanopya::puppetmaster::repository':
    stage => 'system'
  }

  package { 'puppetmaster':
    ensure  => present,
    require => Class["kanopya::puppetmaster::repository"],
    name    => $operatingsystem ? {
      /(RedHat|CentOS|Fedora)/ => 'puppet-server',
      default                  => 'puppetmaster'
    },
  }

  class { 'puppetdb':
    listen_address     => "0.0.0.0",
    ssl_listen_address => "0.0.0.0",
    require            => Class["kanopya::puppetmaster::repository"],
  }

  class { 'puppetdb::master::config':
    puppetdb_server   => "${fqdn}",
    strict_validation => false,
    manage_config     => false,
    restart_puppet    => true,
    require           => Class['puppetdb']
  }

  class { 'puppetdb::master::puppetdb_conf':
    server => "${fqdn}",
    port   => 8081
  }

  file { '/etc/puppet/fileserver.conf':
    path    => '/etc/puppet/fileserver.conf',
    ensure  => present,
    mode    => 0644,
    content => template('kanopya/fileserver.conf.erb'),
    notify  => Service[$puppetdb::params::puppet_service_name]
  }
}
