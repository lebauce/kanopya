class kanopya::openstack::glance(
    $dbserver,
    $password,
    $keystone,
    $email,
    $database_name      = 'glance',
    $database_user      = 'glance',
    $database_password  = 'glance',
    $keystone_user      = 'glance',
    $keystone_password  = 'glance',
    $rabbit_user        = 'glance',
    $rabbit_password    = 'glance',
    $rabbit_virtualhost = '/'
) {
    tag("kanopya::glance")

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

    @@keystone_user { "${keystone_user}":
        ensure   => present,
        password => "${keystone_password}",
        email    => "${email}",
        tenant   => 'services',
        tag      => "${keystone}"
    }

    @@keystone_user_role { "${keystone_user}@services":
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
        keystone_user     => "${keystone_user}",
        keystone_password => "${keystone_password}",
        sql_connection    => "mysql://${database_user}:${database_password}@${dbserver}/${database_name}",
        require           => [ Class['kanopya::openstack::repository'],
                               Exec['/usr/bin/glance-manage db_sync'] ]
    }

    class { 'glance::registry':
        verbose           => 'True',
        debug             => 'True',
        auth_type         => '',
        keystone_tenant   => 'services',
        keystone_user     => "${keystone_user}",
        keystone_password => "${keystone_password}",
        sql_connection    => "mysql://${database_user}:${database_password}@${dbserver}/${database_name}",
        require           => Class['kanopya::openstack::repository']
    }

    class { 'glance::backend::file': }

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::glance']

    if defined(Mount['/var/lib/glance/images']) {
        exec { 'chown glance:glance /var/lib/glance/images':
            subscribe => Mount['/var/lib/glance/images'],
            refreshonly => true
        }
    }
}
