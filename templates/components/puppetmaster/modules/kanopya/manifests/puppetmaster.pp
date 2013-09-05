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
        default : {
            fail("Unsupported operatingsystem : ${operatingsystem}. Only Debian, Ubuntu and Debian are supported")
        }
    }
}

class kanopya::puppetmaster::install {
    package { 'puppetmaster':
        name => $operatingsystem ? {
            /(Red Hat|CentOS|Fedora)/ => 'puppet-server',
            default => 'puppetmaster'
        },
        ensure => present,
        require => Apt::Source['puppetlabs'],
    }

    class { 'puppetdb':
    }

    class { 'puppetdb::master::config':
        require => Class['puppetdb']
    }
}

class kanopya::puppetmaster {
    class { 'kanopya::puppetmaster::repository': } ->
    class { 'kanopya::puppetmaster::install': }
}
