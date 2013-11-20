class kanopya::executor($logdir, $user, $password, $amqpuser, $amqppassword, $lib) {
    require kanopya::common

    if ($components[kanopyaexecutor][master] == 1) {
        rabbitmq_user { "${amqpuser}":
            admin    => true,
            password => "${amqppassword}",
            provider => "rabbitmqctl",
        }

        rabbitmq_user_permissions { "${amqpuser}@/":
            configure_permission => '.*',
            write_permission     => '.*',
            read_permission      => '.*',
            provider             => 'rabbitmqctl',
        }
    }

    file { "/opt/kanopya/conf/executor.conf":
        ensure => present,
        content => template('kanopya/executor.conf.erb'),
    }

    file { "/opt/kanopya/conf/executor-log.conf":
        ensure => present,
        content => template('kanopya/executor-log.conf.erb'),
    }

    service { 'kanopya-executor':
        name => 'kanopya-executor',
        ensure => running,
        enable => true,
        require => [ File['/opt/kanopya/conf/executor.conf'],
                     File['/opt/kanopya/conf/executor-log.conf'] ]
    }

    # Do not install the package on the master node as it would
    # overwrite the sources in case they where fetched from git
    if ($components[kanopyaexecutor][master] == 0) {
        case $operatingsystem {
            /(?i)(centos|redhat)/ : {
                package { 'kanopya-executor':
                    ensure  => installed,
                    before  => Service['kanopya-executor'],
                }
            }
        }
    }
}
