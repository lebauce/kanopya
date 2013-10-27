class kanopya::common {
    case $operatingsystem {
        /(?i)(centos|redhat)/ : {
            include kanopya::mysql::repos::rh

            yumrepo { 'kanopya':
                baseurl  => 'http://download.kanopya.org/yum/centos/6/x86_64/',
                gpgcheck => '0',
                enabled  => '1',
            }

            yumrepo { 'magnum':
                baseurl  => 'http://rpm.mag-sol.com/Centos/6/x86_64/',
                gpgcheck => '0',
                enabled  => '1',
            }

            yumrepo { 'rpmforge':
                baseurl  => 'http://apt.sw.be/redhat/el6/en/x86_64/rpmforge',
                gpgcheck => '0',
                enabled  => '1',
            }
        }
    }

    file { [ "/opt", "/opt/kanopya", "/opt/kanopya/conf" ]:
        ensure => "directory",
    }

    file { "/opt/kanopya/conf/libkanopya.conf":
        ensure => present,
        content => template('kanopya/libkanopya.conf.erb'),
        require => File['/opt/kanopya/conf']
    }

    $logdir = $lib[logdir]
    if ! defined (Exec["mkdir-${logdir}"]) {
        exec { "mkdir-${logdir}":
            command => "mkdir -p ${logdir}"
        }
    }

    group { 'kanopya':
        ensure => present
    }

    user { 'kanopya':
        ensure  => present,
        gid     => 'kanopya',
        require => Group['kanopya']
    }
}
