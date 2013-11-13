class kanopya::puppetmaster::repository {
    $release = downcase($lsbdistcodename)
    $os = downcase($operatingsystem)

    case $operatingsystem {
        /(?i)(debian|ubuntu)/ : {
            @apt::source { 'puppetlabs':
                location   => "http://apt.puppetlabs.com/",
                release    => $release,
                repos      => 'main',
                key        => '4BD6EC30',
                key_server => 'keyserver.ubuntu.com',
                before     => [ Package['puppetdb'],
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

class kanopya::puppetmaster::install {
    package { 'puppetmaster':
        name => $operatingsystem ? {
            /(RedHat|CentOS|Fedora)/ => 'puppet-server',
            default => 'puppetmaster'
        },
        ensure => present,
        require => Class["kanopya::puppetmaster::repository"],
    }

    class { 'puppetdb':
        listen_address => "0.0.0.0"
    }

    class { 'puppetdb::master::config':
        puppetdb_server => 'centos-kanopya-appliance',
        require => Class['puppetdb']
    }
}

class kanopya::puppetmaster {
    class { 'kanopya::puppetmaster::repository': } ->
    class { 'kanopya::puppetmaster::install': }
}
