class kanopya::executor(
  $logdir       = "/var/log/kanopya",
  $user         = "executor",
  $password     = "K4n0pY4",
  $amqpuser     = "executor",
  $amqppassword = "K4n0pY4",
  $sshkey       = undef,
  $sshpubkey    = undef,
) {
  include kanopya::common

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
    ensure  => present,
    content => template('kanopya/executor.conf.erb'),
  }

  file { "/opt/kanopya/conf/executor-log.conf":
    ensure  => present,
    content => template('kanopya/executor-log.conf.erb'),
  }

  service { 'kanopya-executor':
    name    => 'kanopya-executor',
    ensure  => running,
    enable  => true,
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

    file { '/root/.ssh/kanopya_rsa':
      ensure  => present,
      mode    => 0600,
      owner   => 'root',
      group   => 'root',
      source  => "puppet:///kanopyaexecutor/kanopya_rsa",
      before  => Service['kanopya-executor'],
    }

    file { '/root/.ssh/kanopya_rsa.pub':
      ensure  => present,
      mode    => 0600,
      owner   => 'root',
      group   => 'root',
      source  => "puppet:///kanopyaexecutor/kanopya_rsa.pub",
      before  => Service['kanopya-executor'],
    }
  }
}
