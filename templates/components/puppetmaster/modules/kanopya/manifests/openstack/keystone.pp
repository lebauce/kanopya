class kanopya::openstack::keystone(
  $admin_password     = "admin",
  $email              = "nothing@nothing.com",
  $database_name      = "keystone",
  $database_user      = "keystone",
  $database_password  = "keystone"
) {
  tag("kanopya::keystone")

  $dbserver = $components[keystone][mysql][mysqld][tag]
  $dbip = $components[keystone][mysql][mysqld][ip]

  if ! defined(Class['kanopya::openstack::repository']) {
    class { 'kanopya::openstack::repository': }
  }

  if ($components[keystone][master] == 1) {
    @@mysql::db { "${database_name}":
      user     => "${database_user}",
      password => "${database_password}",
      host     => "${ipaddress}",
      grant    => ['all'],
      tag      => "${dbserver}",
    }

    class { 'keystone::endpoint':
      public_address   => $components[keystone][access][keystone_service][ip],
      admin_address    => "${fqdn}",
      internal_address => "${fqdn}",
    }
  }
  else {
    @@database_user { "${database_user}@${ipaddress}":
      password_hash => mysql_password("${database_password}"),
      tag           => "${dbserver}"
    }

    @@database_grant { "${database_user}@${ipaddress}/${database_name}":
      privileges => ['all'],
      tag        => "${dbserver}"
    }
  }

  class { 'keystone::roles::admin':
    email        => "${email}",
    password     => "${admin_password}",
    require      => Exec['/usr/bin/keystone-manage db_sync'],
    admin_tenant => 'openstack'
  }

  class { '::keystone':
    bind_host      => $components[keystone][listen][keystone_service][ip],
    verbose        => true,
    debug          => true,
    sql_connection => "mysql://${database_user}:${database_password}@${dbip}/${database_name}",
    catalog_type   => 'sql',
    admin_token    => 'admin_token',
    before         => [ Class['keystone::roles::admin'],
        Exec['/usr/bin/keystone-manage db_sync'] ]
  }

  exec { "/usr/bin/keystone-manage db_sync":
    path => "/usr/bin:/usr/sbin:/bin:/sbin",
  }

  Keystone_user <<| tag == "${fqdn}" |>>
  Keystone_user_role <<| tag == "${fqdn}" |>>
  Keystone_service <<| tag == "${fqdn}" |>>
  Keystone_endpoint <<| tag == "${fqdn}" |>>

  Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::keystone']
}
