class kanopya::openstack::glance(
    $email,
    $database_name      = 'glance',
    $database_user      = 'glance',
    $database_password  = 'glance',
    $keystone_user      = 'glance',
    $keystone_password  = 'glance'
) {
    tag("kanopya::glance")

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    if ($components['glance']['master'] == 1) {
        @@mysql::db { "${database_name}":
            user     => "${database_user}",
            password => "${database_password}",
            host     => "${ipaddress}",
            grant    => ['all'],
            tag      => "${components['glance']['mysql']['mysqld']['tag']}",
        }

        @@keystone_user { "${keystone_user}":
            ensure   => present,
            password => "${keystone_password}",
            email    => "${email}",
            tenant   => 'services',
            tag      => "${components['glance']['keystone']['keystone']['tag']}"
        }

        @@keystone_user_role { "${keystone_user}@services":
            ensure  => present,
            roles   => 'admin',
            tag     => "${components['glance']['keystone']['keystone']['tag']}"
        }

        @@keystone_service { 'glance':
            ensure      => present,
            type        => 'image',
            description => "Openstack Image Service",
            tag         => "${components['glance']['keystone']['keystone']['tag']}"
        }
    }
    else {
        @@database_user { "${database_user}@${ipaddress}":
            password_hash => mysql_password("${database_password}"),
            tag           => "${components['glance']['mysql']['mysqld']['tag']}"
        }

        @@database_grant { "${database_user}@${ipaddress}/${database_name}":
            privileges => ['all'],
            tag        => "${components['glance']['mysql']['mysqld']['tag']}"
        }
    }

    if ! defined(Exec['/usr/bin/glance-manage db_sync']) {
        exec { "/usr/bin/glance-manage db_sync":
            path => "/usr/bin:/usr/sbin:/bin:/sbin",
        }
    }

    class { 'glance::registry':
        auth_type         => '',
        bind_host         => $admin_ip,
        keystone_tenant   => 'services',
        keystone_user     => "${keystone_user}",
        keystone_password => "${keystone_password}",
        sql_connection    => "mysql://${database_user}:${database_password}@${components['glance']['mysql']['mysqld']['ip']}/${database_name}",
        require           => [ Class['kanopya::openstack::repository'],
                               Exec['/usr/bin/glance-manage db_sync'] ]
    }

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::glance']

    if defined(Mount['/var/lib/glance/images']) {
        exec { 'chown glance:glance /var/lib/glance/images':
            subscribe => Mount['/var/lib/glance/images'],
            refreshonly => true
        }
    }
}
