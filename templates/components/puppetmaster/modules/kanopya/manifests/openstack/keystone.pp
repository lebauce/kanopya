class kanopya::openstack::keystone(
    $dbserver,
    $dbip,
    $admin_password,
    $email,
    $database_name      = "keystone",
    $database_user      = "keystone",
    $database_password  = "keystone"
) {
    tag("kanopya::keystone")

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    @@mysql::db { "${database_name}":
        user     => "${database_user}",
        password => "${database_password}",
        host     => "${ipaddress}",
        grant    => ['all'],
        tag      => "${dbserver}",
    }

    class { 'keystone::endpoint':
        public_address   => "${fqdn}",
        admin_address    => "${fqdn}",
        internal_address => "${fqdn}",
    }

    class { 'keystone::roles::admin':
        email        => "${email}",
        password     => "${admin_password}",
        require      => Exec['/usr/bin/keystone-manage db_sync'],
        admin_tenant => 'openstack'
    }

    class { '::keystone':
        bind_host      => $admin_ip,
        verbose        => true,
        debug          => true,
        sql_connection => "mysql://${database_user}:${database_password}@${dbserver}/${database_name}",
        catalog_type   => 'sql',
        admin_token    => 'admin_token',
        before         => [ Class['keystone::roles::admin'],
                            Exec['/usr/bin/keystone-manage db_sync'] ]
    }

    exec { "/usr/bin/keystone-manage db_sync":
        path    => "/usr/bin:/usr/sbin:/bin:/sbin",
    }

    Keystone_user <<| tag == "${fqdn}" |>>
    Keystone_user_role <<| tag == "${fqdn}" |>>
    Keystone_service <<| tag == "${fqdn}" |>>
    Keystone_endpoint <<| tag == "${fqdn}" |>>

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::keystone']
}
