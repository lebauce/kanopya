class kanopya::front (
  $amqpuser     = "api",
  $amqppassword = "K4n0pY4",
  $logdir       = "/var/log/kanopya"
) {
  include kanopya::common

  if ($components[kanopyafront][master]) {
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

  file { "/opt/kanopya/conf/webui-log.conf":
    ensure  => present,
    content => template('kanopya/webui-log.conf.erb'),
  }

  service { 'kanopya-front':
    name    => 'kanopya-front',
    ensure  => running,
    enable  => true,
    require => [ File['/opt/kanopya/conf/webui-log.conf'] ]
  }

  # Do not install the package on the master node as it would
  # overwrite the sources in case they where fetched from git
  if ($components[kanopyafront][master] == 0) {
    case $operatingsystem {
      /(?i)(centos|redhat)/ : {
        package { 'kanopya-front':
          ensure  => installed,
          before  => Service['kanopya-front'],
        }
      }
    }
  }
}
