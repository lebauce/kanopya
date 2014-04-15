class kanopya::openstack::cinder::server(
  $email              = "nothing@nothing.com",
  $database_name      = "cinder",
  $database_user      = "cinder",
  $database_password  = "cinder",
  $keystone_user      = "cinder",
  $keystone_password  = "cinder",
  $rabbit_password    = "cinder",
  $rabbit_user        = "cinder",
  $rabbit_virtualhost = "/"
) {
  tag("kanopya::cinder")

  $dbip = $components[cinder][mysql][mysqld][ip]
  $dbserver = $components[cinder][mysql][mysqld][tag]
  $keystone = $components[cinder][keystone][keystone_admin][tag]
  $keystone_ip = $components[cinder][keystone][keystone_admin][ip]
  $amqpserver = $components[cinder][amqp][amqp][tag]
  $rabbits = $components[cinder][amqp][nodes]

  if ! defined(Class['kanopya::openstack::repository']) {
    class { 'kanopya::openstack::repository':
      stage => 'system',
    }
  }

  require 'mysql::python'

  if ! defined(Class['::cinder']) {
    class { '::cinder':
      sql_connection    => "mysql://${database_user}:${database_password}@${dbip}/${database_name}",
      rabbit_hosts    => $rabbits,
      rabbit_userid     => "${rabbit_user}",
      rabbit_password   => "${rabbit_password}",
      rabbit_virtual_host => "${rabbit_virtualhost}"
    }
  }

  class { 'cinder::scheduler': }

  class { 'cinder::volume': }

  if ($components[cinder][master] == 1) {
    @@mysql::db { "${database_name}":
      user     => "${database_user}",
      password => "${database_password}",
      host     => "${ipaddress}",
      tag      => $dbserver
    }

    @@rabbitmq_user { "${rabbit_user}":
      admin    => true,
      password => "${rabbit_password}",
      provider => 'rabbitmqctl',
      tag      => $amqpserver
    }

    @@rabbitmq_user_permissions { "${rabbit_user}@${rabbit_virtualhost}":
      configure_permission => '.*',
      write_permission     => '.*',
      read_permission      => '.*',
      provider             => 'rabbitmqctl',
      tag                  => $amqpserver
    }

    @@keystone_user { "${keystone_user}":
      ensure   => present,
      password => "${keystone_password}",
      email    => "${email}",
      tenant   => 'services',
      tag      => $keystone
    }

    @@keystone_user_role { "${keystone_user}@services":
      ensure  => present,
      roles   => 'admin',
      tag     => $keystone
    }

    @@keystone_service { 'cinder':
      ensure      => present,
      type        => "volume",
      description => "Cinder Volume Service",
      tag         => $keystone
    }

    $cinder_access_ip = $components[cinder][access][volume_api][ip]
    @@keystone_endpoint { "RegionOne/cinder":
      ensure       => present,
      public_url   => "http://${cinder_access_ip}:8776/v1/\$(tenant_id)s",
      admin_url    => "http://${fqdn}:8776/v1/\$(tenant_id)s",
      internal_url => "http://${fqdn}:8776/v1/\$(tenant_id)s",
      tag          => $keystone
    }
  }
  else {
    @@database_user { "${database_user}@${ipaddress}":
      password_hash => mysql_password("${database_password}"),
      tag           => $dbserver
    }
    @@database_grant { "${database_user}@${ipaddress}/${database_name}":
      privileges => ['all'],
      tag        => $dbserver
    }
  }

  class { 'cinder::api':
    keystone_auth_host => $keystone_ip,
    keystone_tenant    => 'services',
    keystone_user      => $keystone_user,
    keystone_password  => $keystone_password,
    bind_host          => $components[cinder][listen][volume_api][ip],
  }

  exec { "/usr/bin/cinder-manage db sync":
    path    => "/usr/bin:/usr/sbin:/bin:/sbin",
    require => Class['cinder'],
  }

  cinder_config {
    "DEFAULT/enabled_backends": value => "nfs-backend,iscsi-backend,ceph-backend";
    "DEFAULT/quota_volumes": value => -1;
    "DEFAULT/nfs_mount_options": value => "rw"
  }

  package { 'qemu-utils':
    ensure => installed,
    name => 'qemu-utils',
  }   

  Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::cinder::server']
}
