class kanopya::rabbitmq (
  $disk_nodes = [],
  $cookie = ""
) {
  tag("kanopya::amqp")

  case $operatingsystem {
    /(?i)(debian|ubuntu)/ : {
      $rabbitmq_repo = 'rabbitmq::repo::apt'
      $rabbitmq_repo_stage = 'system'
    }
    /(?i)(redhat|centos)/ : {
      $rabbitmq_repo = 'rabbitmq::repo::rhel'
      $rabbitmq_repo_stage = 'main'
    }
  }

  package { 'erlang':
    ensure => installed
  }

  class { $rabbitmq_repo:
    stage => $rabbitmq_repo_stage
  }

  class { 'rabbitmq::server':
    wipe_db_on_cookie_change => true,
    config_cluster           => true,
    cluster_disk_nodes       => $disk_nodes,
    erlang_cookie            => $cookie,
    node_ip_address          => $components[amqp][listen][amqp][ip],
    package_name             => $operatingsystem ? {
      /(?i)(centos|redhat|fedora)/ => 'rabbitmq-server.noarch',
      default                      => 'rabbitmq-server'
    },
    require                  => Class[$rabbitmq_repo]
  }

  Rabbitmq_user <<| tag == "${fqdn}" |>>
  Rabbitmq_user_permissions <<| tag == "${fqdn}" |>>
  Rabbitmq_vhost <<| tag == "${fqdn}" |>>
}

