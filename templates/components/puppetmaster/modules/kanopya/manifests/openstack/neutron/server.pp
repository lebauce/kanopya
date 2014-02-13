class kanopya::openstack::neutron::server(
  $email              = 'nothing@nothing.com',
  $bridge_flat        = 'br-flat',
  $database_name      = 'neutron',
  $database_user      = 'neutron',
  $database_password  = 'neutron',
  $keystone_user      = 'neutron',
  $keystone_password  = 'neutron',
  $rabbit_user        = 'neutron',
  $rabbit_password    = 'neutron',
  $rabbit_virtualhost = '/'
) {
  tag("kanopya::neutron")

  $dbserver = $components[neutron][mysql][mysqld][tag]
  $dbip = $components[neutron][mysql][mysqld][ip]
  $keystone = $components[neutron][keystone][keystone_admin][tag]
  $amqpserver = $components[neutron][amqp][amqp][tag]
  $rabbits = $components[neutron][amqp][nodes]

  if ! defined(Class['kanopya::openstack::repository']) {
    class { 'kanopya::openstack::repository':
      stage => 'system',
    }
  }

  if ! defined(Class['kanopya::openstack::neutron::common']) {
    class { 'kanopya::openstack::neutron::common':
      rabbit_password    => "${rabbit_password}",
      rabbit_hosts       => $rabbits,
      rabbit_user    => "${rabbit_user}",
      rabbit_virtualhost => "${rabbit_virtualhost}"
    }
  }

  class { '::neutron::server':
    auth_password => "${keystone_password}",
    auth_host     => "${keystone}",
    require       => Class['kanopya::openstack::repository']
  }

  if ($components[neutron][master] == 1) {
    @@mysql::db { "${database_name}":
      user     => "${database_user}",
      password => "${database_password}",
      host     => "${ipaddress}",
      tag      => "${dbserver}"
    }

    @@rabbitmq_user { "${rabbit_user}":
      admin    => true,
      password => "${rabbit_password}",
      provider => 'rabbitmqctl',
      tag      => "${amqpserver}"
    }

    @@rabbitmq_user_permissions { "${rabbit_user}@${rabbit_virtualhost}":
      configure_permission => '.*',
      write_permission     => '.*',
      read_permission      => '.*',
      provider             => 'rabbitmqctl',
      tag                  => "${amqpserver}"
    }

    @@keystone_user { "${keystone_user}":
      ensure   => present,
      password => "${keystone_password}",
      email    => "${email}",
      tenant   => "services",
      tag      => "${keystone}"
    }

    @@keystone_user_role { "${keystone_user}@services":
      ensure  => present,
      roles   => 'admin',
      tag     => "${keystone}"
    }

    @@keystone_service { 'neutron':
      ensure      => present,
      type        => "network",
      description => "Neutron Networking Service",
      tag         => "${keystone}"
    }

    $neutron_access_ip = $components[neutron][access][neutron][ip]
    @@keystone_endpoint { "RegionOne/neutron":
      ensure       => present,
      public_url   => "http://${neutron_access_ip}:9696",
      admin_url    => "http://${fqdn}:9696",
      internal_url => "http://${fqdn}:9696",
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

  class { 'neutron::plugins::ovs':
    sql_connection      => "mysql://${database_user}:${database_password}@${dbip}/${database_name}",
    tenant_network_type => 'vlan',
    network_vlan_ranges => 'physnetflat:1:1',
    require             => Class['kanopya::openstack::repository']
  }

  class { 'neutron::quota':
    default_quota             => -1,
    quota_network             => -1,
    quota_subnet              => -1,
    quota_port                => -1,
    quota_router              => -1,
    quota_floatingip          => -1,
    quota_security_group      => -1,
    quota_security_group_rule => -1
  }

  if ! has_key($components, "novacompute") {
    neutron_plugin_ovs {
      'SECURITYGROUP/firewall_driver': value => "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver";
    }
  }

  Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::neutron::server']
}
