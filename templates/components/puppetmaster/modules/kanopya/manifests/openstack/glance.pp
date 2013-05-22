class kanopya::openstack::glance($dbserver, $password, $keystone, $email) {
    tag("kanopya::glance")

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    @@mysql::db { 'glance':
        user     => 'glance',
        password => "${password}",
        host     => "${ipaddress}",
        grant    => ['all'],
        tag      => "${dbserver}",
    }

    @@keystone_user { 'glance':
        ensure   => present,
        password => "${password}",
        email    => "${email}",
        tenant   => 'services',
        tag      => "${keystone}"
    }

    @@keystone_user_role { "glance@services":
        ensure  => present,
        roles   => 'admin',
        tag     => "${keystone}"
    }

    @@keystone_service { 'glance':
        ensure      => present,
        type        => 'image',
        description => "Openstack Image Service",
        tag         => "${keystone}"
    }

    @@keystone_endpoint { "RegionOne/glance":
        ensure       => present,
        public_url   => "http://${fqdn}:9292/v2",
        admin_url    => "http://${fqdn}:9292/v2",
        internal_url => "http://${fqdn}:9292/v2",
        tag          => "${keystone}"
    }

    exec { "/usr/bin/glance-manage db_sync":
        path => "/usr/bin:/usr/sbin:/bin:/sbin",
    }

    class { 'glance::api':
        verbose           => 'True',
        debug             => 'True',
        auth_type         => '',
        auth_port         => '35357',
        keystone_tenant   => 'services',
        keystone_user     => 'glance',
        keystone_password => 'glance',
        sql_connection    => "mysql://glance:${password}@${dbserver}/glance",
        require           => [ Class['kanopya::openstack::repository'],
                               Exec['/usr/bin/glance-manage db_sync'] ]
    }

    class { 'glance::registry':
        verbose           => 'True',
        debug             => 'True',
        auth_type         => '',
        keystone_tenant   => 'services',
        keystone_user     => 'glance',
        keystone_password => 'glance',
        sql_connection    => "mysql://glance:${password}@${dbserver}/glance",
        require           => Class['kanopya::openstack::repository']
    }

    class { 'glance::backend::file': }

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::glance']
}
