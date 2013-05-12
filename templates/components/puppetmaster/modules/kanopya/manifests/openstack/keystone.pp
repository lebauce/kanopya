class kanopya::openstack::keystone($dbserver, $dbip, $dbpassword, $adminpassword, $email) {
    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    @@mysql::db { 'keystone':
        user     => 'keystone',
        password => "${dbpassword}",
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
        password     => "${adminpassword}",
        require      => Exec['/usr/bin/keystone-manage db_sync'],
        admin_tenant => 'openstack'
    }

    class { '::keystone':
        verbose        => true,
        debug          => true,
        sql_connection => "mysql://keystone:${dbpassword}@${dbserver}/keystone",
        catalog_type   => 'sql',
        admin_token    => 'admin_token',
        before => Class['keystone::roles::admin'],
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
