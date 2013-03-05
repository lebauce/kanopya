class kanopya::linux ($sourcepath) {
    case $operatingsystem {
        CentOS, Fedora: { $haltpath = "/etc/rc.d/rc0.d/"
                          $netscript = "K[0-9][0-9]network"
                          $iscsiscript = "K[0-9][0-9]iscsi" 
                        }
        
        Ubuntu:         { $haltpath = "/etc/rc0.d/" 
                          $netscript = "S[0-9][0-9]networking"
                          $iscsiscript = "S[0-9][0-9]open-iscsi" 
                        }
        
        Debian:         { $haltpath = "/etc/rc0.d/"
                          $netscript = "K[0-9][0-9]networking"
                          $iscsiscript = "K[0-9][0-9]umountiscsi" 
                        }
        
        default:        { fail("Unrecognized operating system") }
    }

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

    tidy {'bad-scripts':
        path    => $haltpath,
        recurse => true,
        matches => [ $iscsiscript, $netscript ]
    }

    package { 'ntpdate':
        name   => 'ntpdate',
        ensure => present,
    }
}

