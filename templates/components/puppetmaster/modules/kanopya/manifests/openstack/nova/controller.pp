class kanopya::openstack::nova::controller(
  $admin_password     = 'nova',
  $email              = 'nothing@nothing.com',
  $keystone_user      = 'nova',
  $keystone_password  = 'nova',
  $database_user      = 'nova',
  $database_password  = 'nova',
  $database_name      = 'nova',
  $rabbit_user        = 'nova',
  $rabbit_password    = 'nova',
  $rabbit_virtualhost = '/'
) {
  tag("kanopya::novacontroller")

  $dbserver = $components[novacontroller][mysql][mysqld][tag]
  $dbip = $components[novacontroller][mysql][mysqld][ip]
  $keystone = $components[novacontroller][keystone][keystone_admin][tag]
  $keystone_ip = $components[novacontroller][keystone][keystone_admin][ip]
  $amqpserver = $components[novacontroller][amqp][amqp][tag]
  $rabbits = $components[novacontroller][amqp][nodes]

  if has_key($components[novacontroller], 'quantum') {
    $quantum = $components[novacontroller][quantum][quantum][ip]
  } else {
    $quantum = undef
  }

  if has_key($components[novacontroller], 'glance') {
    $glance_registry = $components[novacontroller][glance][glance_registry][ip]
  } else {
    $glance_registry = undef
  }

  if ! defined(Class['kanopya::openstack::repository']) {
    class { 'kanopya::openstack::repository': }
  }

  exec { "/usr/bin/nova-manage db sync":
    path => "/usr/bin:/usr/sbin:/bin:/sbin",
  }

  if ($components[novacontroller][master] == 1) {
    if $rabbit_virtualhost != "/" {
      @@rabbitmq_vhost { "${rabbit_virtualhost}":
        ensure   => present,
        provider => 'rabbitmqctl',
        tag      => "${amqpserver}"
      }
    }

    @@rabbitmq_user { "${rabbit_user}":
      admin    => true,
      password => "${rabbit_password}",
      provider => 'rabbitmqctl',
      tag      => "${amqpserver}",
    }

    @@rabbitmq_user_permissions { "${rabbit_user}@${rabbit_virtualhost}":
      configure_permission => '.*',
      write_permission     => '.*',
      read_permission      => '.*',
      provider             => 'rabbitmqctl',
      tag                  => "${amqpserver}",
    }

    @@keystone_user { "${keystone_user}":
      ensure   => present,
      password => "${keystone_password}",
      email    => "${email}",
      tenant   => 'services',
      tag      => "${keystone}",
    }

    @@keystone_user_role { "${keystone_user}@services":
      ensure  => present,
      roles   => 'admin',
      tag     => "${keystone}",
    }

    @@keystone_service { 'compute':
      ensure      => present,
      type        => "compute",
      description => "Nova Compute Service",
      tag         => "${keystone}"
    }

    @@mysql::db { "${database_name}":
      user     => "${database_user}",
      password => "${database_password}",
      host     => "${ipaddress}",
      grant    => ['all'],
      charset  => 'latin1',
      tag      => "${dbserver}",
    }

    $compute_access_ip = $components[novacontroller][access][compute_api][ip]
    @@keystone_endpoint { "RegionOne/compute":
      ensure       => present,
      public_url   => "http://${compute_access_ip}:8774/v2/\$(tenant_id)s",
      admin_url    => "http://${fqdn}:8774/v2/\$(tenant_id)s",
      internal_url => "http://${fqdn}:8774/v2/\$(tenant_id)s",
      tag          => "${keystone}"
    }
  }
  else {
    @@database_user { "${database_user}@${ipaddress}":
      password_hash => mysql_password("${database_password}"),
      tag           => "${dbserver}",
    }

    @@database_grant { "${database_user}@${ipaddress}/${database_name}":
      privileges => ['all'] ,
      tag        => "${dbserver}"
    }
  }

  if ! defined(Class['kanopya::openstack::nova::common']) {
    class { 'kanopya::openstack::nova::common':
      glance             => $glance_registry,
      quantum            => $quantum,
      keystone           => $keystone_ip,
      email              => $email,
      sql_connection     => "mysql://${database_user}:${database_password}@${dbip}/${database_name}",
      rabbits            => $rabbits,
      rabbit_user        => $rabbit_user,
      rabbit_password    => $rabbit_password,
      rabbit_virtualhost => $rabbit_virtualhost
    }
  }

  class { 'nova::api':
    enabled          => true,
    admin_password   => "${admin_password}",
    auth_host        => $keystone_ip,
    api_bind_address => $components[novacontroller][listen][compute_api][ip],
    metadata_listen  => $components[novacontroller][listen][metadata_api][ip],
    require          => [ Exec["/usr/bin/nova-manage db sync"],
                          Class['kanopya::openstack::repository'] ]
  }

  nova_paste_api_ini {
    'filter:ratelimit/paste.filter_factor': value => "nova.api.openstack.compute.limits:RateLimitingMiddleware.factory";
    'filter:ratelimit/limits': value => '(POST, "*", .*, 100000, MINUTE);(POST, "*/servers", ^/servers, 500000, DAY);(PUT, "*", .*, 100000, MINUTE);(GET, "*changes-since*", .*changes-since.*, 3, MINUTE);(DELETE, "*", .*, 100000, MINUTE)';
  }

  class { 'nova::scheduler':
    enabled => true,
    require => Class['kanopya::openstack::repository']
  }

  class { 'nova::objectstore':
    enabled => true,
    require => Class['kanopya::openstack::repository']
  }

  class { 'nova::cert':
    enabled => true,
    require => Class['kanopya::openstack::repository']
  }

  class { 'nova::vncproxy':
    enabled => true,
    require => Class['kanopya::openstack::repository']
  }

  class { 'nova::consoleauth':
    enabled => true,
    require => Class['kanopya::openstack::repository']
  }

  class { 'nova::conductor':
    enabled => true
  }

  nova_config {
    'DEFAULT/ram_allocation_ratio': value => '100';
    'DEFAULT/cpu_allocation_ratio': value => '100';
  }

  class { 'nova::quota':
    quota_instances                       => -1,
    quota_cores                           => -1,
    quota_ram                             => -1,
    quota_volumes                         => -1,
    quota_gigabytes                       => -1,
    quota_floating_ips                    => -1,
    quota_metadata_items                  => -1,
    quota_max_injected_files              => -1,
    quota_max_injected_file_content_bytes => -1,
    quota_max_injected_file_path_bytes    => -1,
    quota_security_groups                 => -1,
    quota_security_group_rules            => -1,
    quota_key_pairs                       => -1
  }

  if defined(Class['kanopya::apache']) {
    class { 'openstack::horizon':
      secret_key    => 'dummy_secret_key',
      keystone_host => $keystone_ip
    }
  }

  Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::nova::controller']
}

